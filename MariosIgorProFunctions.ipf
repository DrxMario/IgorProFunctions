#pragma rtGlobals=1		// Use modern global access method.

Menu "Mario's Functions"
	"Avg Timecourse"
	"Double Pulse Timecourse"
	"IV"
	"Current at V from IV"
	"Tail Current GV"
	"Noise Analysis"
	"Normalize Full"
End

// NB/DISCLAIMER: This program has only been tested on data acquired using Patchmaster
// with pulse protocols I defined. These functions may or may not work out of the box with your
// data, so BE CAREFUL when you use these procedures!
// Sanity checks are ALWAYS a good idea.

function avgTimecourse()
	variable numTraces
	string currWaves, expNum, absExpNum, pulNum
	Prompt numTraces, "Enter the number of traces"
	Prompt expNum, "What is the exp num?"
	Prompt absExpNum, "What is the absolute exp num?"
	Prompt pulNum, "What is the pulse num?"
	DoPrompt "Which traces are you going to analyze?",  numTraces, expNum, absExpNum, pulNum
	if (V_flag)
		return -1; // user canceled
	endif
	
	// get a list of all the waves to analyze
	currWaves = WaveList("PMPulse_"+expNum+"_"+pulNum+"*"+"I-mon",";","")
	variable index = 0
	String currWave
	
	// make the waves to store the I values
	Make/O/N=(numTraces) avgI // store all the avg current measurements
	
	do
		currWave = StringFromList(index, currWaves)
		if (strlen(currWave) == 0)
			break
		elseif (index >= numTraces)
			break
		endif
		
		wave tempw = $currWave // make wave reference
		
		// Add the tail current measurement in the ItPeaks wave
		avgI[index] = mean(tempw)
		
		index += 1
	while(1)
	
	// show the graphs
	String newAvg = "avgI_" + absExpNum + "_" + expNum + "_" + pulNum
	Duplicate avgI, $newAvg
	Display $newAvg

end function

function DoublePulseTimecourse()
	variable numTraces, startLow = 0.0305, endLow = 0.11, startHigh = 0.1105, endHigh = 0.19
	string currWaves, expNum, absExpNum, pulNum
	Prompt numTraces, "Enter the number of traces"
	Prompt expNum, "What is the exp num?"
	Prompt absExpNum, "What is the absolute exp num?"
	Prompt pulNum, "What is the pulse num?"
	Prompt startLow, "Start Low (s)"
	Prompt endLow, "End Low (s)"
	Prompt startHigh, "Start High (s)"
	Prompt endHigh, "End High (s)"
	DoPrompt "Which traces are you going to analyze?",  numTraces, absExpNum, expNum, pulNum, startLow, endLow, startHigh, endHigh
	if (V_flag)
		return -1; // user canceled
	endif
	
	// get a list of all the waves to analyze
	currWaves = WaveList("PMPulse_"+expNum+"_"+pulNum+"*"+"I-mon",";","")
	variable index = 0
	String currWave
	
	// make the waves to store the I values
	Make/O/N=(numTraces) avgIlow, avgIhigh // store all the avg current measurements
	
	do
		currWave = StringFromList(index, currWaves)
		if (strlen(currWave) == 0)
			break
		elseif (index >= numTraces)
			break
		endif
		
		wave tempw = $currWave // make wave reference
		
		// Add the avg current measurements in the avgI waves
		avgIhigh[index] = mean(tempw, startHigh, endHigh)
		avgIlow[index] = mean(tempw, startLow, endLow)
				
		index += 1
	while(1)
	
	// show the graphs
	String newAvgLow = "avgIlow_" + absExpNum + "_" + pulNum
	Duplicate /O avgIlow, $newAvgLow
	String newAvgHigh = "avgIhigh_" + absExpNum + "_" + pulNum
	Duplicate /O avgIhigh, $newAvgHigh
	Display $newAvgLow, $newAvgHigh
	ModifyGraph zero(left)=8
	Label bottom "Sweep #"

end function

function IV()
	//Dialog variables
	String currWaves, expNum, pulNum, absExpNum, expName
	variable deltaV = 10, numTraces = 21, startV = -100, xStart = 0.0303, xEnd = 0.1085

	// First, prompt the user for the wave family to use. It must have been preloaded using PPT and named as: PMPulse_exp_prot_sweep
	Prompt absExpNum, "Enter the *absolute* experiment number (eg: 150) in between the quotes (\"#\")"
	Prompt expNum, "Enter the *relative* experiment number (eg: 1, 2) in between the quotes (\"#\")"
	Prompt pulNum, "Enter the pulse protocol number for the experiment in between the quotes (\"#\")"
	Prompt deltaV, "Enter the deltaV between sweeps"
	Prompt numTraces, "Enter the number of traces"
	Prompt startV, "Enter the starting test voltage"
	Prompt xStart, "Enter the start time (x) in seconds"
	Prompt xEnd, "Enter the end time in seconds"
	Prompt expName, "Enter the name of the experiment"
	DoPrompt "Which traces are you going to analyze?", absExpNum, expNum, pulNum, deltaV, numTraces, startV, xStart, xEnd, expName
	if (V_flag)
		return -1; // user canceled
	endif

	// get a list of all the waves to analyze
	currWaves = WaveList("PMPulse_"+expNum+"_"+pulNum+"*",";","")
	Display

	// analyze the waves, looking at tail currents for P(o) and steady state current for rectification
	variable index = 0
	String currWave
	
	// make the waves to store the I values, and scale them based on the V
	Make/O/N=(numTraces) avgI // store all the tail current measurements
	SetScale /P x, startV, deltaV, avgI
	
	do
		currWave = StringFromList(index, currWaves)
		if (strlen(currWave) == 0)
			break
		elseif (index >= numTraces)
			break
		endif
		
		String newName = "PMPulse_"+absExpNum+"_"+expNum+"_"+pulNum+"_"+num2str(index+1)+"_IV" // need to make a new name to include the absolute exp number
		wave tempw = $currWave // make wave reference
		Duplicate/O tempw, $newName /WAVE=currw
		
		// make the graph
		AppendToGraph currw
		// Add the tail current measurement in the ItPeaks wave
		avgI[index] = mean(currw, xStart, xEnd)

		index += 1
	while(1)
	ModifyGraph rgb=(0,0,0)
	ModifyGraph font="Helvetica";DelayUpdate
	Label bottom "Time (s)\u#2"
	Label left "Current (\U)"
	
	// show the graphs
	Display avgI
	ModifyGraph mode=3,marker=8
	ModifyGraph rgb=(0,0,0)
	ModifyGraph font="Helvetica";DelayUpdate
	Label bottom "Voltage (mV)"
	Label left "Current (\U)"
	String rnStr = "IV_"+expName+"_"+ absExpNum + "_" + expNum + "_" + pulNum
	KillWaves/Z $rnstr
	Rename avgI, $rnstr
	
end	

function CurrentAtVfromIV()
	String currWaves, currWave, expName
	Variable Va, Ia
	
	Prompt expName, "Name of the experiment"
	Prompt Va, "Voltage"
	DoPrompt "I(V)", expName, Va
	if (V_flag)
		return -1; // user canceled
	endif
	
	currWaves = WaveList("*",";","WIN:") // get the waves from the top window
	variable index = 0, vhalf
	wave w_coef
	Make /O /N=1000 temp_Is
	
	do
		currWave = StringFromList(index, currWaves)
		if (strlen(currWave) == 0)
			break
		endif
		
		wave tempw = $currWave // make wave reference
		temp_Is[index] = tempw(Va) // get current ratio
		index+=1
	while(1)
	
	String newName="I"+num2str(Va) +"_"+ expName
	Duplicate/R=[0,index-1] /O temp_Is, $newName
	Display $newName
	Label left "I\\B"+num2str(Va)+"\\M"
	ModifyGraph mode=3, marker=19
end

function TailCurrentGV()
	//Dialog variables
	String currWaves, expNum, pulNum, absExpNum, expName
	variable deltaV = 10, numTraces = 21, startV = -100, xStart = 0.11, xEnd = 0.1165

	// First, prompt the user for the wave family to use. It must have been preloaded using PPT and named as: PMPulse_exp_prot_sweep
	Prompt absExpNum, "Enter the *absolute* experiment number (eg: 150) in between the quotes (\"#\")"
	Prompt expNum, "Enter the *relative* experiment number (eg: 1, 2) in between the quotes (\"#\")"
	Prompt pulNum, "Enter the pulse protocol number for the experiment in between the quotes (\"#\")"
	Prompt deltaV, "Enter the deltaV between sweeps"
	Prompt numTraces, "Enter the number of traces"
	Prompt startV, "Enter the starting test voltage"
	Prompt xStart, "Enter the start time (x) in seconds"
	Prompt xEnd, "Enter the end time in seconds"
	Prompt expName, "Enter the name of the experiment"
	DoPrompt "Which traces are you going to analyze?", absExpNum, expNum, pulNum, deltaV, numTraces, startV, xStart, xEnd, expName
	if (V_flag)
		return -1; // user canceled
	endif

	// get a list of all the waves to analyze
	currWaves = WaveList("PMPulse_"+expNum+"_"+pulNum+"*",";","")
	Display

	// analyze the waves, looking at tail currents for P(o) and steady state current for rectification
	variable index = 0
	String currWave
	
	// make the waves to store the I values, and scale them based on the V
	Make/O/N=(numTraces) tailI // store all the tail current measurements
	SetScale /P x, startV, deltaV, tailI
	
	do
		currWave = StringFromList(index, currWaves)
		if (strlen(currWave) == 0)
			break
		elseif (index >= numTraces)
			break
		endif
		
		String newName = "PMPulse_"+absExpNum+"_"+expNum+"_"+pulNum+"_"+num2str(index+1)+"_tailGV" // need to make a new name to include the absolute exp number
		wave tempw = $currWave // make wave reference
		Duplicate/O tempw, $newName /WAVE=currw
		
		// make the graph
		AppendToGraph currw
		// Add the tail current measurement in the ItPeaks wave
		tailI[index] = WaveMin(currw, xStart, xEnd)

		index += 1
	while(1)
	ModifyGraph rgb=(0,0,0)
	ModifyGraph font="Helvetica";DelayUpdate
	Label bottom "Time (s)\u#2"
	
	// normalize tailI - current recorded at -100mV, so inward (negative) current
	tailI /= -1
	//variable tailMin = waveMin(tailI)
	//tailI -= tailMin
	//variable tailMax = waveMax(tailI)
	//tailI /= tailMax
	
	// show the graphs
	Display tailI
	ModifyGraph mode=3,marker=8
	ModifyGraph rgb=(0,0,0)
	ModifyGraph font="Helvetica";DelayUpdate
	Label bottom "mV"
	String rnStr = "tailGV_"+expName+"_"+ absExpNum + "_" + expNum + "_" + pulNum
	KillWaves/Z $rnstr
	Rename tailI, $rnstr
	
end	

function NoiseAnalysis()
	variable numTraces, sweepStart = 0.12, sweepEnd = 0.19
	string currWaves, expNum, absExpNum, pulNum
	Prompt numTraces, "Enter the number of traces"
	Prompt absExpNum, "What is the absolute exp num?"
	Prompt expNum, "What is the exp num?"
	Prompt pulNum, "What is the pulse num?"
	Prompt sweepStart, "Analysis start time (s)"
	Prompt sweepEnd, "Analysis end time (s)"
	DoPrompt "Which traces are you going to analyze?",  numTraces, absExpNum, expNum, pulNum, sweepStart, sweepEnd
	if (V_flag)
		return -1; // user canceled
	endif
	
	// get a list of all the waves to analyze
	currWaves = WaveList("PMPulse_"+expNum+"_"+pulNum+"*"+"I-mon",";","")
	variable index = 0
	String currWave
	
	// make the waves to store the I values
	Make/O/N=(numTraces) sweepVar // store the variance measurement for each sweep
	
	do
		currWave = StringFromList(index, currWaves)
		if (strlen(currWave) == 0)
			break
		elseif (index >= numTraces)
			break
		endif
		
		wave tempw = $currWave // make wave reference
		
		// Add the avg current measurements in the avgI waves
		sweepVar[index] = variance(tempw, sweepStart, sweepEnd)
				
		index += 1
	while(index < numTraces)
	
	// show the graphs
	String newVar = "sweepVar_" + absExpNum + "_" + pulNum
	Duplicate /O sweepVar, $newVar
	Display $newVar

end function


function NormalizeFull()
	// Variables
	String currWaves, currWave, newName
	variable waveIndex
	
	 // get the waves from the top window
	currWaves=WaveList("*", ";","WIN:")
	waveIndex = 0
	print currWaves
	
	// set up the graph
	Display
	
	do
		// duplicate each wave from the top window
		currWave = StringFromList(waveIndex, currWaves)
		if (strlen(currWave) == 0)
			break;
		endif
		wave tempw = $currWave // make wave reference
		
		newName = "norm_" + currWave 
		Duplicate/O tempw, $newName 
		WAVE currw = $newName
		
		// normalize waves
		variable mn = WaveMin(currw)
		variable mx = WaveMax(currw)
		
		currw = (currw - mn)/ (mx-mn)
		
		waveIndex +=1
		
		AppendToGraph currw
	while(1)
end