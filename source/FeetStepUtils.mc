
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
    	dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_WHITE);
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