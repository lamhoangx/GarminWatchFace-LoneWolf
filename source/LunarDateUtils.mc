//算法来自 https://github.com/CutePandaSh/zhdate/blob/master/zhdate/__init__.py
using Toybox.System;
using Toybox.Time.Gregorian;

class LunarDateUtils{
    /**
     * 从2021年到2100年的农历月份数据代码 20位二进制代码表示一个年份的数据， 
     * 前四位0:表示闰月为29天，1:表示闰月为30天
     * 中间12位：从左起表示1-12月每月的大小，1为30天，0为29天
     * 最后四位：表示闰月的月份，0表示当年无闰月
     * 前四位和最后四位应该结合使用，如果最后四位为0，则不考虑前四位
     * 例： 
     * 1901年代码为 19168，转成二进制为 0b100101011100000, 最后四位为0，当年无闰月，月份数据为 010010101110 分别代表12月的大小情况
     * 1903年代码为 21717，转成二进制为 0b0000101010011010101，最后四位为5，当年为闰五月，首四位为0，闰月为29天， 月份数据为 010101001101，分别代表12月的大小情况
     *
    */
    var CHINESE_YEAR_CODE = [
        27296,  44368,  23378,  19296,  42726,  42208,  53856,  60005,
        54576,  23200,  30371,  38608,  19195,  19152,  42192, 118966,
        53840,  54560,  56645,  46496,  22224,  21938,  18864,  42359,
        42160,  43600, 111189,  27936,  44448,  84835,  37744,  18936,
        18800,  25776,  92326,  59984,  27296, 108228,  43744,  37600,
        53987,  51552,  54615,  54432,  55888,  23893,  22176,  42704,
        21972,  21200,  43448,  43344,  46240,  46758,  44368,  21920,
        43940,  42416,  21168,  45683,  26928,  29495,  27296,  44368,
        84821,  19296,  42352,  21732,  53600,  59752,  54560,  55968,
        92838,  22224,  19168,  43476,  41680,  53584,  62034,  54560
    ];
    //从2021年，至2100年每年的农历春节的公历日期
    var CHINESE_NEW_YEAR_DATE = [
        20210212, 20220201, 20230122, 20240210, 20250129,
        20260217, 20270206, 20280126, 20290213, 20300203,
        20310123, 20320211, 20330131, 20340219, 20350208,
        20360128, 20370215, 20380204, 20390124, 20400212,
        20410201, 20420122, 20430210, 20440130, 20450217,
        20460206, 20470126, 20480214, 20490202, 20500123,
        20510211, 20520201, 20530219, 20540208, 20550128,
        20560215, 20570204, 20580124, 20590212, 20600202,
        20610121, 20620209, 20630129, 20640217, 20650205,
        20660126, 20670214, 20680203, 20690123, 20700211,
        20710131, 20720219, 20730207, 20740127, 20750215,
        20760205, 20770124, 20780212, 20790202, 20800122,
        20810209, 20820129, 20830217, 20840206, 20850126,
        20860214, 20870203, 20880124, 20890210, 20900130,
        20910218, 20920207, 20930127, 20940215, 20950205,
        20960125, 20970212, 20980201, 20990121, 21000209
    ];

    function initialize(){

    }
    
    /**
     * 获取公历对应的农历日期
     */
    public function getLunarDate(year,month,day){
        var lunarYear;
        var lunarMonth;
        var lunarDay = 0;
        var leapMonth;

        lunarYear = year;
        /*处理公历初的农历问题 2022 1 19*/
        var  newYearDateY = CHINESE_NEW_YEAR_DATE[year - 2021]/10000;
        var  newYearDateM = CHINESE_NEW_YEAR_DATE[year - 2021]/100%100;
        var  newYearDateD = CHINESE_NEW_YEAR_DATE[year - 2021]%100;
        // System.println("newYearDateY:"+newYearDateY);
        // System.println("newYearDateM:"+newYearDateM);
        // System.println("newYearDateD:"+newYearDateD);

        if(newYearDateY > year 
            || (newYearDateY == year && newYearDateM > month)
            || (newYearDateY == year && newYearDateM == month && newYearDateD > day)){
            lunarYear--;
        }
        // System.println("lunarYear:"+lunarYear);

        var todayMoment = Gregorian.moment({
            :year   => year,
            :month  => month,
            :day    => day,
            :hour   => 0,
            :minute => 0
        });
        newYearDateY = CHINESE_NEW_YEAR_DATE[lunarYear - 2021]/10000;
        newYearDateM = CHINESE_NEW_YEAR_DATE[lunarYear - 2021]/100%100;
        newYearDateD = CHINESE_NEW_YEAR_DATE[lunarYear - 2021]%100;
        var newYearDateMoment = Gregorian.moment({
            :year   => newYearDateY,
            :month  => newYearDateM,
            :day    => newYearDateD,
            :hour   => 0,
            :minute => 0
        });
        var durationPassed = todayMoment.subtract(newYearDateMoment);
        var daysPassed = durationPassed.value()/86400;
        // System.println("daysPassed:"+daysPassed);

        var yearCode = CHINESE_YEAR_CODE[lunarYear - 2021];
        var monthDays = decode(yearCode);
        var size = monthDays.size();
        var acc = accumulate(monthDays);
        var monthTemp = 0;
        for(var i = 0;i < size;i++){
            if (daysPassed + 1 <= acc[i]){
                monthTemp = i + 1;//?
                // System.println("monthTemp:"+monthTemp);
                // System.println("monthDays[i]:"+monthDays[i]);
                // System.println("acc[i]:"+acc[i]);
                // System.println("daysPassed:"+daysPassed);
                lunarDay = monthDays[i] - (acc[i] - daysPassed) + 1;
                // System.println("lunarDay:"+lunarDay);

                break;
            }
        }
        leapMonth = false;
        if ((yearCode & 0xf) == 0 || monthTemp <= (yearCode & 0xf)){
            lunarMonth = monthTemp;
        }else{
            lunarMonth = monthTemp - 1;
        }
        if ((yearCode & 0xf) != 0 && monthTemp == (yearCode & 0xf) + 1){
            leapMonth = true;
        }
        
        // System.println("day:"+lunarDay);
        return formatLunarDate(lunarYear, lunarMonth, lunarDay, leapMonth);
    }

  	public function  formatLunarDate( lunarYear, lunarMonth, lunarDay, leapMonth) {
  		var rResult = Lang.format("$1$-$2$", [(lunarDay).format("%02d"), (lunarMonth).format("%02d")]);
  		return rResult;
  	}
        
    /**
     * yearCode 从年度代码数组中获取的代码,已经转换成整数
     * 获取当前年度代码解析以后形成的每月天数数组，已将闰月嵌入对应位置，即有闰月的年份返回长度为13，否则为12
     * 0b0000101010011010101
     10110110101 0010
     **/
    public function decode(yearCode){
        var monthDays;
        //闰月的情况
        var runYue = yearCode & 0xf;
        if(runYue > 0){
            monthDays = [0,0,0,0,0,0, 0,0,0,0,0,0, 0];
            if ((yearCode >> 16) != 0){
                monthDays[runYue] = 30;
            }else{
                monthDays[runYue] = 29;
            }
            for(var i = 5;i < 17;i++){
                if((yearCode >> (i - 1)) & 1 == 1){
                    //比如闰三月，下标 0 1 2 都正常计算，然后跳过3 继续计算4以后
                    if(17 - i > runYue){
                        monthDays[17 - i] = 30;
                    }else{
                        monthDays[16 - i] = 30;
                    }
                }else{
                    if(17 - i > runYue){
                        monthDays[17 - i] = 29;
                    }else{
                        monthDays[16 - i] = 29;
                    }
                }
            }
        }else{
            monthDays = [0,0,0,0,0,0, 0,0,0,0,0,0];
            for(var i = 5;i < 17;i++){
                if((yearCode >> (i - 1)) & 1 == 1){
                    monthDays[17 - i - 1] = 30;
                }else{
                    monthDays[17 - i - 1] = 29;
                }
            }
        }
        // System.println("有无闰月："+runYue);
        // System.println("monthDays: "+monthDays);
        return monthDays;
    }

    function accumulate(monthDays){
        var days = 0;
        var size = monthDays.size();
        var acc = new [size];
        for(var i = 0;i < size;i++){
            days += monthDays[i];
            acc[i] = days;
        }
        // System.println(acc);

        return acc;
    }

//    public function testLunarDate20210627(logger){
//        var dateUtils = new LunarDateUtils();
//        var date = dateUtils.getLunarDate(2021,6,27);
//        System.print(date);
//        return date.equals("五月十八");
//    }

}