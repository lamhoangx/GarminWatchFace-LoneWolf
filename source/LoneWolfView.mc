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
	// Time
	hidden var timer;
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
	
	// Optimize threshold
	hidden var currentMin;

    function initialize() {
        WatchFace.initialize();
        
        var mySettings = System.getDeviceSettings();
        isScreenShapeRect = System.getDeviceSettings().screenShape == System.SCREEN_SHAPE_RECTANGLE;
        // Screen 
        screenWidth = mySettings.screenWidth;
        screenHeight = mySettings.screenHeight;
        // Moon coordinate, moon's bitmap is 32x32
        moonSX = (screenWidth) / 2 - 6;
        moonSY = 2;
        // Pin
        pinState = -1;
        pinPosX = screenWidth / 2 - 12;
        pinPosY = screenHeight - 18;
        // Kcal
        kcalIcon = Ui.loadResource(Rez.Drawables.kcal_bg);
        kcalPosX = screenWidth / 2 + 4;
        kcalPosY = screenHeight - 18;
        
        currentMin = -1;
        
        // background
        backdrop = Ui.loadResource(Rez.Drawables.backdrop);
        
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    	timer = new WatchUi.Text({
            :text=>"",
            :color=>Graphics.COLOR_BLACK,
            :font=>Graphics.FONT_SYSTEM_NUMBER_MEDIUM,
            :locX =>screenWidth/2 - 32,
            :locY=> (screenHeight/2) - 48,
            :justification=>Graphics.TEXT_JUSTIFY_LEFT
        });
        weeker = new WatchUi.Text({
            :text=>"",
            :color=>Graphics.COLOR_BLACK,
            :font=>Graphics.FONT_SYSTEM_TINY,
            :locX =>screenWidth/2,
            :locY=>(screenHeight/2),
            :justification=>Graphics.TEXT_JUSTIFY_LEFT
        });
        pinStatus = new WatchUi.Text({
            :text=>"",
            :color=>Graphics.COLOR_BLACK,
            :font=>Graphics.FONT_XTINY,
            :locX =>pinPosX - 2,
            :locY=>pinPosY - 2,
            :justification=>Graphics.TEXT_JUSTIFY_RIGHT
        });

		if(debugInfo) {
	        kcalGoalInfo = new WatchUi.Text({
	            :text=>"",
	            :color=>Graphics.COLOR_BLACK,
	            :font=>Graphics.FONT_XTINY,
	            :locX =>screenWidth / 2 + 4,
	            :locY=>screenHeight - 36,
	            :justification=>Graphics.TEXT_JUSTIFY_LEFT
	        });
        }
        currentMin = 0;
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
    	if(!shouldUpdate() && !debugInfo) {
    		return;
    	}
    	
        timer.setText(getCurrentTime());
        weeker.setText(getCurrentDate());

        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);
               
        // draw background image
        dc.drawBitmap(0, 0, backdrop);
        
        // DateTime
        timer.draw(dc);
        weeker.draw(dc);
        
        //
        drawSeparateCenter(dc);
        // Pin
        var batStatus = System.getSystemStats().battery.toNumber();	
        drawPinStatus(dc, batStatus);
        // Kcal
        drawCaloGoalProgress(dc);
        
        // moon pharse
        dc.drawBitmap(moonSX, moonSY, calcMoon());
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() as Void {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() as Void {
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
    function getCurrentTime() {
    	var clockTime = System.getClockTime();
    	currentMin = clockTime.min;
        var timeString = Lang.format("$1$:$2$", [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]);
        return timeString;
    }
    function getCurrentDate() {
    	var now = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
		var month = now.month;
		var day = now.day;
		var day_of_week = now.day_of_week;
		var weekdays = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"];
		
		var strDayOfW = weekdays[day_of_week-1];
		var strDay = day.format("%02d");
		var strMonth = month.format("%02d");
		
        var timeString = Lang.format("$1$, $2$-$3$", [strDayOfW, strDay, strMonth]);
		return timeString;
    }
    
    function drawSeparateCenter(dc as Dc) {
    	dc.fillCircle(screenWidth / 2, screenHeight - 8, 1);
    }
    
    function drawCaloGoalProgress(dc as Dc) {
    	
    	dc.drawBitmap(kcalPosX, kcalPosY, kcalIcon);
    	
    	if(isScreenShapeRect) {return;}
    	
    	// goal mode
    	var goalMode = Application.getApp().getProperty("CaloriesGoalMode");
    	var kcalGoal = 0;
    	
        if(goalMode <= 0) { // Auto
        	kcalGoal = getDefaultActiveCaloriesGoal();
        } else if(goalMode == 1) { // Manual
        	kcalGoal = Application.getApp().getProperty("CaloriesGoalInput");
        } else if(goalMode == 2) { // Select
        	kcalGoal = 100;
        } else if(goalMode == 3) {
        	kcalGoal = 200;
        } else if(goalMode == 4) {
        	kcalGoal = 300;
        } else if(goalMode == 5) {
        	kcalGoal = 400;
        } else if(goalMode == 6) {
        	kcalGoal = 500;
        } else if(goalMode == 7) {
        	kcalGoal = 600;
        } else if(goalMode == 8) {
        	kcalGoal = 700;
        } else if(goalMode == 9) {
        	kcalGoal = 800;
        } else if(goalMode == 10) {
        	kcalGoal = 900;
        } else if(goalMode == 11) {
        	kcalGoal = 1000;
        }

        if(kcalGoal <= 0) {
        	kcalGoal = getDefaultActiveCaloriesGoal();
        }
    	if(kcalGoal <= 0) {return;}
    
    	var calo = calActiveCalories();
    	if(kcalGoalInfo != null) { // debug
    		calo = 100;
    	}
    	var percent = calo.toNumber().toFloat()/kcalGoal.toNumber().toFloat();
    	var totalDiagram = 83 + 90;
    	var currentDiagram = totalDiagram * percent;
    	
    	var rootCoorX = screenWidth / 2;
    	var rootCoorY = screenHeight / 2;
    	
    	var edgePadding = 2;
		var diagramRadius = screenWidth/2 - 2;
		var diagramStartDeg = -83;
		var diagramEndDeg = currentDiagram + diagramStartDeg;
		if(diagramEndDeg > 90) {
			diagramEndDeg = 90;
		}
		
		if(kcalGoalInfo != null) { // debug info
			kcalGoalInfo.setText(Lang.format("$1$/$2$", [calo.toString(), kcalGoal]));
			kcalGoalInfo.draw(dc);
		}
		
		if(diagramEndDeg <= diagramStartDeg) {
			return;
		}
		
		
//		dc.setAntiAlias(true);
    	dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
    	// draw bottom line
    	var bPadding = 5;
    	var barBoldH = 5;
    	var bX = rootCoorX - bPadding;
    	var bY = screenHeight - bPadding;

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
    		pinStatus.setColor(Graphics.COLOR_BLACK);
    	}
    	if(pinState == pinC && pinIcon != null) {
    		// can reuse pin resource
    	} else {
    		pinState = pinC;
    		pinIcon = null;
    		if(pinState == 2) {
    			pinIcon = Ui.loadResource(Rez.Drawables.battery_f);
    		} else if(pinState == 1) {
    			pinIcon = Ui.loadResource(Rez.Drawables.battery_m);
    		} else {
    			pinIcon = Ui.loadResource(Rez.Drawables.battery_l);
    		}	
    	}
    
    	dc.drawBitmap(pinPosX, pinPosY, pinIcon);
    	pinStatus.setText(progress.format("%02d"));
    	pinStatus.draw(dc);
    }
    
    // formula to calculate the active calories
    function calActiveCalories() {
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
		} else else {
			return 80;
		}
	}
    
}
