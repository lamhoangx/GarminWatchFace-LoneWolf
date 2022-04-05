import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;

using Toybox.WatchUi;
using Toybox.Graphics as Gfx;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;
using Toybox.Time.Gregorian;
using Toybox.Time;
using Toybox.WatchUi as Ui;
using Toybox.ActivityMonitor as AM;
using Toybox.Activity;

using Toybox.Position;
using Toybox.System;

class LoneWolfView extends WatchUi.WatchFace {

	var debugInfo = false;
	
	// backdrop image
	var backdrop;

	var isScreenShapeRect;
	// Dimension
	var screenWidth;
	var screenHeight;
	// coordinate moon status
	hidden var moonSX;
	hidden var moonSY;
	// Day
	hidden var cYear = -1;
	hidden var cMonth = -1;
	hidden var cDay = -1;
	// Time
	hidden var hourTimer;
	hidden var minutesTimer;
	hidden var weeker;
	// Pin 9x16
	var pinState;
	hidden var pinIcon;
	hidden var pinStatus;
	hidden var pinPosX;
	hidden var pinPosY;
	// Kcal
	hidden var kcalIcon;
	hidden var kcalPosX;
	hidden var kcalPosY;
	hidden var kcalGoalInfo;
	// Feet
	hidden var feetIcon;
	hidden var feetPosX;
	hidden var feetPosY;
	hidden var feetStepCurrentInfo;
	hidden var feetGoalInfo;
	
	// Optimize threshold
	hidden var currentMin;
	hidden var daysInfo = null;

    function initialize() {
        WatchFace.initialize();
        
        var mySettings = System.getDeviceSettings();
        isScreenShapeRect = System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_RECTANGLE;
        // Screen 
        screenWidth = mySettings.screenWidth;
        screenHeight = mySettings.screenHeight;
        // Moon coordinate, moon's bitmap is 32x32
        moonSX = (screenWidth / 2) + 10;
        moonSY = (screenHeight / 2) + 41;
        // Pin
        pinState = -1;
        pinPosX = screenWidth / 2 - 12;
        pinPosY = screenHeight - 18;
        // Kcal
        kcalIcon = Ui.loadResource(Rez.Drawables.kcal_bg);
        kcalPosX = screenWidth / 2 - 12;
        kcalPosY = screenHeight - 32;
        // Feet
        feetIcon = Ui.loadResource(Rez.Drawables.feet);
        feetPosX = screenWidth / 2 + 4;
        feetPosY = screenHeight - 18;
        
        currentMin = -1;
        
        // background
        backdrop = Ui.loadResource(Rez.Drawables.backdrop);
        
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
        requestReDraw();
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    	hourTimer = new WatchUi.Text({
            :text=>"",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_NUMBER_THAI_HOT,
            :locX=>(screenWidth/2),
            :locY=>(screenHeight/2) - 16,
            :justification=>Graphics.TEXT_JUSTIFY_VCENTER|Graphics.TEXT_JUSTIFY_CENTER
        });
        minutesTimer = new WatchUi.Text({
            :text=>"",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_NUMBER_MEDIUM,
            :locX=>(screenWidth/2) + 66,
            :locY=>(screenHeight/2) - 66,
            :justification=>Graphics.TEXT_JUSTIFY_CENTER
        });
        weeker = new WatchUi.Text({
            :text=>"",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_XTINY,
            :locX =>screenWidth/2 + 75,
            :locY=>(screenHeight/2) + 40,
            :justification=>Graphics.TEXT_JUSTIFY_VCENTER|Graphics.TEXT_JUSTIFY_RIGHT
        });
        pinStatus = new WatchUi.Text({
            :text=>"",
            :color=>Graphics.COLOR_WHITE,
            :font=>Graphics.FONT_XTINY,
            :locX =>pinPosX - 2,
            :locY=>pinPosY - 2,
            :justification=>Graphics.TEXT_JUSTIFY_RIGHT
        });

		kcalGoalInfo = new WatchUi.Text({
	            :text=>"",
	            :color=>Graphics.COLOR_WHITE,
	            :font=>Graphics.FONT_XTINY,
	            :locX =>screenWidth / 2 - 14,
	            :locY=>screenHeight - 26,
	            :justification=>Graphics.TEXT_JUSTIFY_VCENTER|Graphics.TEXT_JUSTIFY_RIGHT
	        });
	        
	    feetStepCurrentInfo = new WatchUi.Text({
	            :text=>"",
	            :color=>Graphics.COLOR_WHITE,
	            :font=>Graphics.FONT_XTINY,
	            :locX =>screenWidth / 2 + 6,
	            :locY=>screenHeight - 26,
	            :justification=>Graphics.TEXT_JUSTIFY_VCENTER|Graphics.TEXT_JUSTIFY_LEFT
	        });
	        
	    feetGoalInfo = new WatchUi.Text({
	            :text=>"",
	            :color=>Graphics.COLOR_WHITE,
	            :font=>Graphics.FONT_XTINY,
	            :locX =>screenWidth - 2,
	            :locY=>screenHeight / 2 + 8,
	            :justification=>Graphics.TEXT_JUSTIFY_VCENTER|Graphics.TEXT_JUSTIFY_RIGHT
	        });
	        
        requestReDraw();
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
    	if(!shouldUpdate() && !debugInfo) {
    		return;
    	}
    	
        hourTimer.setText(getCurrentHourTime());
        minutesTimer.setText(getCurrentMinutesTime());
        
        weeker.setText(getCurrentDate());

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
               
        // draw background image
        dc.drawBitmap(0, 0, backdrop);
        
        // DateTime
        hourTimer.draw(dc);
        minutesTimer.draw(dc);
        weeker.draw(dc);
        
        //
        drawSeparateCenter(dc);
        // Pin
        var batStatus = System.getSystemStats().battery.toNumber();	
        drawPinStatus(dc, batStatus);
        // Kcal
        drawCaloGoalProgress(dc);
        // Feet
        drawFeetStepProgress(dc);
        
        // moon pharse
        dc.drawBitmap(moonSX, moonSY, calcMoon());
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    	requestReDraw();
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    	requestReDraw();
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
    	requestReDraw();
    }
    
    function requestReDraw() {
    	currentMin = -1;
    	daysInfo = null;
    }
    
    // utils
    function shouldUpdate() {
    	var clockTime = System.getClockTime();
    	if(currentMin == clockTime.min){
    		return false;
    	} 
    	currentMin = clockTime.min;
    	return true;
    }
    function getCurrentHourTime() {
    	var clockTime = System.getClockTime();
    	currentMin = clockTime.min;
        var timeString = Lang.format("$1$", [clockTime.hour.format("%02d")]);
        return timeString;
    }
    function getCurrentMinutesTime() {
    	var clockTime = System.getClockTime();
    	currentMin = clockTime.min;
        var timeString = Lang.format("$1$", [clockTime.min.format("%02d")]);
        return timeString;
    }
    function getCurrentTime() {
    	var clockTime = System.getClockTime();
    	currentMin = clockTime.min;
        var timeString = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        return timeString;
    }
    function getCurrentDate() {
    	var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    	
    	if(daysInfo != null && cYear == now.year && cMonth == now.month && cDay == now.day ) {
    		return daysInfo;
    	}
    	
    	// newest info
    	cYear = now.year;
		cMonth = now.month;
		cDay = now.day;
		
		var day_of_week = now.day_of_week;
		var weekdays = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
		
		var strDayOfW = weekdays[day_of_week-1];
		var strDay = cDay.format("%02d");
		var strMonth = cMonth.format("%02d");
		
		var dateUtils = new LunarDateUtils();
		var lunalTime = dateUtils.getLunarDate(cYear, cMonth, cDay);
		
        daysInfo = Lang.format("$1$, $2$-$3$\n$4$", [strDayOfW, strDay, strMonth, lunalTime]);
		return daysInfo;
    }
    function getCurrentLunarDate() {
    	var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
    	
    	var year = now.year;
		var month = now.month;
		var day = now.day;
		
		var dateUtils = new LunarDateUtils();
		var lunalTime = dateUtils.getLunarDate(year, month, day);
		
		return lunalTime;
    	
    }
    
    function drawSeparateCenter(dc as Dc) {
    	dc.fillCircle(screenWidth / 2, screenHeight - 8, 1);
    }
    
    function drawCaloGoalProgress(dc as Dc) {
        
    	dc.drawBitmap(kcalPosX, kcalPosY, kcalIcon);
    	
		var calo = calActiveCalories();
		kcalGoalInfo.setText(Lang.format("$1$", [calo.toString()]));
		kcalGoalInfo.draw(dc);
		
    }
    function drawFeetStepProgress(dc as Dc) {
    	
    	// icon feet at bottom
    	dc.drawBitmap(feetPosX, feetPosY, feetIcon);
    	// icon feet at 3h direction
    	dc.drawBitmap(screenWidth - 15, screenHeight / 2 + 14, feetIcon);
    	
    	if(isScreenShapeRect) {return;}
    	
    	// current feet  step
		var stepGoal = ActivityMonitor.getInfo().stepGoal;
    	var stepCount = ActivityMonitor.getInfo().steps;
    	if(stepGoal == null || stepCount == null || stepGoal <= 0) {
    		return;
    	}
	
		//
		var startP = 79;
		var endP = 18;
    	var percent = 100;
    	// direction of 6h -> 3h - padding = 83
    	var totalDiagram = startP;
    	var currentDiagram = totalDiagram * percent;
    	
    	var rootCoorX = screenWidth / 2;
    	var rootCoorY = screenHeight / 2;
    	
    	var edgePadding = 5;
		var diagramRadius = screenWidth/2 - 2;
		var diagramStartDeg = -startP;
		var diagramEndDeg = -endP;
		
		
		//dc.setAntiAlias(true);
    	dc.setColor(0x383838, 0x383838);
    	// draw bottom line
    	var bPadding = 5;
    	var barBoldH = 1;
    	var bX = rootCoorX - bPadding;
    	var bY = screenHeight - bPadding;

    	// base line
    	dc.drawArc(rootCoorX, rootCoorY, diagramRadius - edgePadding, Graphics.ARC_COUNTER_CLOCKWISE, diagramStartDeg, diagramEndDeg);
    	// progressBar
    	for(var i = 0; i <  barBoldH; i ++) {
    		dc.drawArc(rootCoorX, rootCoorY, diagramRadius - edgePadding - i, Graphics.ARC_COUNTER_CLOCKWISE, diagramStartDeg, diagramEndDeg);
    	}
    	
    	
    	// draw progress
    	// Draw Current/Goal into
    	
//    	stepGoal = 2550;
//		stepCount = 1028;
    	
    	// draw current step
    	feetStepCurrentInfo.setText(Lang.format("$1$", [stepCount.toString()]));
    	feetStepCurrentInfo.draw(dc);
    	
    	feetGoalInfo.setText(Lang.format("$1$", [stepGoal.toString()]));
    	feetGoalInfo.draw(dc);
    	// draw progress
    	percent = stepCount.toNumber().toFloat()/stepGoal.toNumber().toFloat();
    	// direction of 6h -> 3h - padding = 83
    	currentDiagram = totalDiagram * percent;
    	
		diagramRadius = screenWidth/2 - 2;
		diagramStartDeg = -startP;
		diagramEndDeg = currentDiagram + diagramStartDeg;
		// direction 3h is 0 (coordinate)
		if(diagramEndDeg > -endP) {
			diagramEndDeg = -endP;
		}
		
		if(diagramEndDeg <= diagramStartDeg) {
			return;
		}
		
		
		//dc.setAntiAlias(true);
    	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
    	// draw bottom line
    	bPadding = 5;
    	barBoldH = 3;
    	bX = rootCoorX - bPadding;
    	bY = screenHeight - bPadding;

    	// base line
    	dc.drawArc(rootCoorX, rootCoorY, diagramRadius - edgePadding, Graphics.ARC_COUNTER_CLOCKWISE, diagramStartDeg, diagramEndDeg);
    	// progressBar
    	for(var i = 0; i <  barBoldH; i ++) {
    		dc.drawArc(rootCoorX, rootCoorY, diagramRadius - edgePadding - i, Graphics.ARC_COUNTER_CLOCKWISE, diagramStartDeg, diagramEndDeg);
    	}
   
    }
    
    function drawPinStatus(dc as Dc, progress) {
    	var pinC = 0;
    	if(progress < 15) {
    		// red color for low batery
    		pinC = 0;
    		pinStatus.setColor(Graphics.COLOR_RED);
    	} else {
    		if(progress < 60) {
    			// medium
    			pinC = 1;
    		} else {
    			// hight
    			pinC = 2;
    		}
    		pinStatus.setColor(Graphics.COLOR_WHITE);
    	}
    	if(pinState == pinC && pinIcon != null) {
    		// can reuse pin resource
    	} else {
    		pinIcon = Ui.loadResource(Rez.Drawables.battery);	
    	}
    
    	dc.drawBitmap(pinPosX, pinPosY, pinIcon);
    	pinStatus.setText(progress.format("%02d"));
    	pinStatus.draw(dc);
    }
    
    // formula to calculate the active calories
    function calActiveCalories() {
//    	if(true) {
//    		return 88;
//    	}
    	var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var profile = UserProfile.getProfile();
		var age = today.year - profile.birthYear;
		var weight = profile.weight / 1000.0;
		
		var restCalories;
		var activeCalories;
		if (profile.gender == UserProfile.GENDER_MALE) {
			restCalories = 5.2 - 6.116*age + 7.628*profile.height + 12.2*weight;
		} else {// female
			restCalories = -197.6 - 6.116*age + 7.628*profile.height + 12.2*weight;
		}
		restCalories = Math.round((today.hour*60+today.min) * restCalories / 1440 ).toNumber();
		var curCalories = Toybox.ActivityMonitor.getInfo().calories;
		if(curCalories > restCalories) {
			activeCalories = curCalories - restCalories;
			return activeCalories;
		}
		return 0;
		
	}
	
	
	// estimate calories goal by age
	function getDefaultActiveCaloriesGoal() {
		var today = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var profile = UserProfile.getProfile();
		var age = today.year - profile.birthYear;
		if(age > 80) {
			return 30;
		} else if(age > 75) {
			return 40;
		} else if(age > 70) {
			return 45;
		} else if(age > 65) {
			return 55;
		} else if(age > 60) {
			return 80;
		} else if(age > 65) {
			return 90;
		} else if(age > 50) {
			return 120;
		} else if(age > 45) {
			return 140;
		} else if(age > 40) {
			return 160;
		} else if(age > 35) {
			return 180;
		} else if(age > 30) {
			return 190;
		} else if(age > 25) {
			return 250;
		} else if(age > 20) {
			return 300;
		} else if(age > 18) {
			return 250;
		} else if(age > 16) {
			return 200;
		} else if(age > 14) {
			return 180;
		} else if(age > 10) {
			return 150;
		} else {
			return 80;
		}
	}
    
}
