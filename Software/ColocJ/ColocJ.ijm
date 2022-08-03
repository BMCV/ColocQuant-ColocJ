var max_rib_center = false;
var max_rib_edges = false;
var box_plots = false;
var detection_data = false;
var return_value = "";
var coloc_folder = "";
macro "ColocJ" {
	max_rib_center = false;
	max_rib_edges = false;
	box_plots = false; 
	if (nImages == 0 ){
	showMessage("ColocJ","An image needs to be opened before starting the macro. \nThe image can contain a polygon ROI or no selection.");
	return;
	}
	a = startingdialog();
	if (a == "triple"){
		if (selectionType() == -1) {
			no_selection();
		}
		else {
			if (selectionType() != 2) {
				showMessage("ColocJ","Please only use the polygon selection tool.");
			}
			else {
				polygon();
			}	
		}
	}
	if (a == "double"){
		if (selectionType() == -1) {
			no_selection_double();
		}
		else {
			if (selectionType() != 2) {
				showMessage("ColocJ","Please only use the polygon selection tool.");
			}
			else {
				polygon_double();
			}	
		}
	}
	if (a == "detection"){
			if (selectionType() != 2 && selectionType() != -1) {
				showMessage("ColocJ","Please only use the polygon selection tool.");
			}
			else {
				detection();
			}	
	}
}
function startingdialog() {
	Dialog.create("Choose Visualization");
	labels = newArray("Triple Colocalization", "Double Colocalization","Single Detection", "Maxwell or Ribbon (center)", "Maxwell or Ribbon (nodes)", "Boxplot");
	defaults = newArray(true, false, false, false, false, false);
	Dialog.addCheckboxGroup(2, 3, labels, defaults); 
	Dialog.show();
	selected = newArray(defaults.length);
	for (i = 0; i < lengthOf(defaults); i++) {
		selection = Dialog.getCheckbox();
		selected[i] = selection;
	}
	if ((selected[3]==1 && selected[4]==1) || (selected[1] == 1 && selected[0] == 1) ||(selected[1] == 1 && selected[2] == 1)||(selected[2] == 1 && selected[0] == 1) || (selected[2] == 0 && selected[1] == 0 && selected[0] == 0)){
		showMessage("ColocJ","Please decide for a visualization type.");
		return_value = startingdialog();
	}
	else if ((selected[2]==1 && selected[3]==1)|| (selected[2]==1 && selected[4]==1) || (selected[2]==1 && selected[5]==1)) {
			showMessage("ColocJ","These options are no available for the detection macro.");
			return_value = startingdialog();
	}
	else {
		if (selected[0]==1){ return_value = "triple";}
		if (selected[1]==1){ return_value = "double";}
		if (selected[2]==1){ return_value = "detection";}
		if (selected[3]==1){ max_rib_center = true;}
		if (selected[4]==1){ max_rib_edges = true;}
		if (selected[5]==1){ box_plots = true;}
		//if (selected[3]==1){ detection_data = true;}
	}
	
	return return_value;
}
function polygon_double() {
	selected_x_y = newArray(0);
	int1 = newArray(0);
	int2 = newArray(0);
	area1 = newArray(0);
	area2 = newArray(0);
	frame_array = newArray(0);
	counter = 0;


	coloc_folder = getDirectory("Choose a Colocalization directory");
	folder_name = File.getName(coloc_folder);
	datafile = coloc_folder + "double_colocalization/results/coloc_data.csv";
	if (File.exists(datafile) == false){
		showMessage("ColocJ","There was no coloc_data.csv file found in the directory.\nPlease only select directories created by ColocQuant.");
		exit();
	}
	file = File.openAsString(datafile);
	headers = newArray(0);
	LineArray = split(file, "\n");
	DataArray = split(LineArray[0], ",");
	headers = DataArray;
	if(endsWith(headers[4], "1")==true){ch1="Ch"+"1";ch1_int = 1;}
	if(endsWith(headers[4], "2")==true){ch1="Ch"+"2";ch1_int = 2;}
	if(endsWith(headers[8], "2")==true){ch2="Ch"+"2";ch2_int = 2;}
	if(endsWith(headers[8], "3")==true){ch2="Ch"+"3";ch2_int = 3;}
	run("Clear Results");
	Overlay.remove;

	imageID = getImageID();
	size = 3;
	if(max_rib_center || max_rib_edges){
		create_color_ribbon(ch1, ch2, size);
		ribbonID = getImageID();
	}
	setBatchMode(true);
	selectImage(imageID);
	//necessary, because Duplicate works weird with selections
	getSelectionCoordinates(xpoints, ypoints);
	Roi.remove;
	run("Duplicate...", "duplicate");
	copyID = getImageID();
	selectImage(copyID);
	makeSelection("polygon", xpoints, ypoints);
	selectImage(imageID);
	makeSelection("polygon", xpoints, ypoints);
	
	for (i = 1; i < LineArray.length; i++) {
		DataArray = split(LineArray[i], ",");  //Dataarray contains information for a single colocalization
		number = parseInt(DataArray[0]);
		mean_x = parseInt(DataArray[1]);  //get coordinates of colocalization
		mean_y = parseInt(DataArray[2]);
		frame = parseInt(DataArray[3]);
		if(selectionContains(mean_x, mean_y)){//see if current colocalozation coordinates are also in ROi
			int1 = Array.concat(int1,parseFloat(DataArray[6]));
			int2 = Array.concat(int2,parseFloat(DataArray[10]));
			area1 = Array.concat(area1,parseFloat(DataArray[7]));
			area2 = Array.concat(area2,parseFloat(DataArray[11]));
			frame_array = Array.concat(frame_array, parseInt(DataArray[3]));

			x1 = parseFloat(DataArray[4]);
			x2 = parseFloat(DataArray[8]);
			y1 = parseFloat(DataArray[5]);
			y2 = parseFloat(DataArray[9]);
			if (max_rib_center) {
				selectImage(copyID);
				Stack.setFrame(frame);
				Stack.setChannel(ch1_int);
				//Stack.setPosition(1, 1, frame) //channel, slize, frame
				color1 = getPixel(mean_x, mean_y);
				Stack.setChannel(ch2_int);
				color2 = getPixel(mean_x, mean_y);
				fill_ribbon(color1, color2, ribbonID, size);
			}
			else if (max_rib_edges){
				fill_ribbon(parseFloat(DataArray[6]), parseFloat(DataArray[10]), ribbonID, size);
			}
			point_draw(frame, mean_x, mean_y, number, imageID, true);
			
			for (j = 0; j < 11; j++){
				//parsefloat to convert to number with 4 decimals, tostring so that the number is fully shown in results
				if(j==0){
				setResult("number", counter, number+1);	
				}
				else {
				setResult(headers[j], counter, toString(parseFloat(DataArray[j])));
				}
			}
			counter++;
		}
	}
	setBatchMode(false);
	selectImage(imageID);
	Overlay.show;
	//testing if no colocalization in selection
	if (int1.length < 10 && int1.length != 0) {
		showMessage("ColocJ", "Total number of colocalizations: "+area1.length+".\nThe boxplots might not be accurate for a dataset of this size.");
	}
	if (int1.length == 0) {
		showMessage("ColocJ", "No colocalization found in selected area.");
		exit();
	}
	if (box_plots) {
	filler = newArray(0);
	createBoxPlot(int1, int2, filler,"Intensity ROI "+folder_name, "{,"+ch1+",, "+ch2+",}","Intensity", ch1, ch2);
	Plot.show();
	createBoxPlot(area1, area2, filler, "Area ROI "+folder_name, "{,"+ch1+",, "+ch2+",}", "Area [Pixel]", ch1, ch2);
	Plot.show();
	createFrameGraph(frame_array);
	Plot.show()
	}
	run("Clear Results");
	showMessage("ColocJ","Colocalizations in selected area: "+area1.length);
}
function polygon() {
	selected_x_y = newArray(0);
	int1 = newArray(0);
	int2 = newArray(0);
	int3 = newArray(0);
	area1 = newArray(0);
	area2 = newArray(0);
	area3 = newArray(0);
	x1 = newArray(0);
	x2 = newArray(0);
	x3 = newArray(0);
	y1 = newArray(0);
	y2 = newArray(0);
	y3 = newArray(0);
	frame_array = newArray(0);
	counter = 0;

	coloc_folder = getDirectory("Choose a Colocalization directory");
	folder_name = File.getName(coloc_folder);
	datafile = coloc_folder + "triple_colocalization/results/coloc_data.csv";
	if (File.exists(datafile) == false){
		showMessage("ColocJ","There was no coloc_data.csv file found in the directory.\nPlease only select directories created by ColocQuant.");
		exit();
	}
	file = File.openAsString(datafile);
	headers = newArray(0);
	LineArray = split(file, "\n");
	DataArray = split(LineArray[0], ",");
	headers = DataArray;
	run("Clear Results");
	Overlay.remove;

	imageID = getImageID();
	size = 2;
	if(max_rib_center || max_rib_edges){
		create_maxwell_triangle(size);
		maxwellID = getImageID();
	}
	setBatchMode(true);
	selectImage(imageID);
	//necessary, because Duplicate works weird with selections
	getSelectionCoordinates(xpoints, ypoints);
	Roi.remove;
	run("Duplicate...", "duplicate");
	copyID = getImageID();
	selectImage(copyID);
	makeSelection("polygon", xpoints, ypoints);
	selectImage(imageID);
	makeSelection("polygon", xpoints, ypoints);
	
	width = 295*size;
	height = 256*size;
	for (i = 1; i < LineArray.length; i++) {
		DataArray = split(LineArray[i], ",");  //Dataarray contains information for a single colocalization
		number = parseInt(DataArray[0]);
		mean_x = parseInt(DataArray[1]);  //get coordinates of colocalization
		mean_y = parseInt(DataArray[2]);
		frame = parseInt(DataArray[3]);
		if(selectionContains(mean_x, mean_y)){//see if current colocalozation coordinates are also in ROi
			int1 = Array.concat(int1,parseFloat(DataArray[6]));
			int2 = Array.concat(int2,parseFloat(DataArray[10]));
			int3 = Array.concat(int3,parseFloat(DataArray[14]));
			area1 = Array.concat(area1,parseFloat(DataArray[7]));
			area2 = Array.concat(area2,parseFloat(DataArray[11]));
			area3 = Array.concat(area3,parseFloat(DataArray[15]));
			x1 = parseFloat(DataArray[4]);
			x2 = parseFloat(DataArray[8]);
			x3 = parseFloat(DataArray[12]);
			y1 = parseFloat(DataArray[5]);
			y2 = parseFloat(DataArray[9]);
			y3 = parseFloat(DataArray[13]);
			frame_array = Array.concat(frame_array, parseInt(DataArray[3]));

			if(max_rib_center){
				selectImage(copyID);
				Stack.setFrame(frame);
				Stack.setChannel(1);
				//Stack.setPosition(1, 1, frame) //channel, slize, frame
				red = getPixel(mean_x, mean_y);
				print(red);
				Stack.setChannel(2);
				green = getPixel(mean_x, mean_y);
				Stack.setChannel(3);
				blue = getPixel(mean_x, mean_y);	
				fill_maxwell(mean_x, mean_y, red, green, blue, imageID, maxwellID, width, height, frame);
			}
			else if(max_rib_edges){
				fill_maxwell(mean_x, mean_y, parseFloat(DataArray[6]), parseFloat(DataArray[10]), parseFloat(DataArray[14]), imageID, maxwellID, width, height, frame);
			}
			point_draw(frame, mean_x, mean_y, number, imageID, true);
			triangle_draw(frame, x1, x2, x3, y1, y2, y3, number, imageID);
			
			for (j = 0; j < 16; j++){
				//parsefloat to convert to number with 4 decimals, tostring so that the number is fully shown in results
				if(j==0){
				setResult("number", counter, number+1);	
				}
				else {
				setResult(headers[j], counter, toString(parseFloat(DataArray[j])));
				}
			}
			counter++;
		}
	}
	setBatchMode(false);
	selectImage(imageID);
	Overlay.show;
	//testing if no colocalization in selection
	if (int1.length < 10 && int1.length != 0) {
		showMessage("ColocJ", "Total number of colocalizations: "+area1.length+".\nThe boxplots might not be accurate for a dataset of that size.");
	}
	if (int1.length == 0) {
		showMessage("ColocJ", "No colocalization found in selected area.");
		exit();
	}
	if (box_plots) {
		createBoxPlot(int1, int2, int3, "Intensity ROI "+folder_name, "{,Ch1,, Ch2,, Ch3,}","Intensity", false, false);
		Plot.show();
		createBoxPlot(area1, area2, area3, "Area ROI "+folder_name, "{,Ch1,, Ch2,, Ch3,}", "Area [Pixel]", false, false);
		Plot.show();
		createFrameGraph(frame_array);
		Plot.show()
	}
	showMessage("ColocJ","Colocalizations in selected area: "+area1.length);
}

function no_selection() {

	int1 = newArray(0);
	int2 = newArray(0);
	int3 = newArray(0);
	area1 = newArray(0);
	area2 = newArray(0);
	area3 = newArray(0);
	x1 = newArray(0);
	x2 = newArray(0);
	x3 = newArray(0);
	y1 = newArray(0);
	y2 = newArray(0);
	y3 = newArray(0);
	frame_array = newArray(0);
	
	
	coloc_folder = getDirectory("Choose a Colocalization directory");
	folder_name = File.getName(coloc_folder);
	datafile = coloc_folder + "triple_colocalization/results/coloc_data.csv";
	if (File.exists(datafile) == false){
		showMessage("ColocJ","There was no coloc_data.csv file found in the directory.\nPlease only select directories created by ColocQuant.");
		exit();
	}
	file = File.openAsString(datafile);
	headers = newArray(0);
	LineArray = split(file, "\n");
	DataArray = split(LineArray[0], ",");
	headers = DataArray;
	run("Clear Results");
	Overlay.remove;

	imageID = getImageID();
	size = 2;
	if(max_rib_center || max_rib_edges){
		create_maxwell_triangle(size);
		maxwellID = getImageID();
	}
	setBatchMode(true);
	selectImage(imageID);
	run("Duplicate...", "duplicate");
	copyID = getImageID();
	width = 295*size;	//of the Maxwell triangle
	height = 256*size;	// of the Maxwell triangle
	for (i = 1; i < LineArray.length; i++) {
		DataArray = split(LineArray[i], ",");
		number = parseInt(DataArray[0]);
		mean_x = parseInt(DataArray[1]);  //get coordinates of colocalization
		mean_y = parseInt(DataArray[2]);
		frame = parseInt(DataArray[3]);
		
		//rgb_int = Array.concat(rgb_int,parseFloat(DataArray[3]));
		int1 = Array.concat(int1,parseFloat(DataArray[6]));
		int2 = Array.concat(int2,parseFloat(DataArray[10]));
		int3 = Array.concat(int3,parseFloat(DataArray[14]));
		area1 = Array.concat(area1,parseFloat(DataArray[7]));
		area2 = Array.concat(area2,parseFloat(DataArray[11]));
		area3 = Array.concat(area3,parseFloat(DataArray[15]));
		x1 = parseFloat(DataArray[4]);
		x2 = parseFloat(DataArray[8]);
		x3 = parseFloat(DataArray[12]);
		y1 = parseFloat(DataArray[5]);
		y2 = parseFloat(DataArray[9]);
		y3 = parseFloat(DataArray[13]);
		frame_array = Array.concat(frame_array, parseInt(DataArray[3]));

		if(max_rib_center){
			selectImage(copyID);
			Stack.setFrame(frame);
			Stack.setChannel(1);
			//Stack.setPosition(1, 1, frame) //channel, slize, frame
			red = getPixel(mean_x, mean_y);
			Stack.setChannel(2);
			green = getPixel(mean_x, mean_y);
			Stack.setChannel(3);
			blue = getPixel(mean_x, mean_y);
			fill_maxwell(mean_x, mean_y, red, green, blue, imageID, maxwellID, width, height, frame);
		}
		else if(max_rib_edges){
			fill_maxwell(mean_x, mean_y, parseFloat(DataArray[6]), parseFloat(DataArray[10]), parseFloat(DataArray[14]), imageID, maxwellID, width, height, frame);
		}
		point_draw(frame, mean_x, mean_y, number, imageID, true);
		triangle_draw(frame, x1, x2, x3, y1, y2, y3, number, imageID);
		
		for (j = 0; j < 16; j++){
			if(j==0){
			setResult("number", i-1, number+1);	
			}
			else {
			setResult(headers[j], i-1, toString(parseFloat(DataArray[j])));
			}
		}
	}
	setBatchMode(false);
	//testing if no colocalization at all
	if (int1.length < 10 && int1.length != 0) {
		showMessage("ColocJ","Total number of colocalizations: "+area1.length+".\nThe boxplots might not be accurate for a dataset of that size.");
	}
	if (int1.length == 0) {
		showMessage("ColocJ","No colocalization found.\nPlot cannot be created.");
		exit();
	}
	selectImage(imageID);
	Overlay.show;
	if (box_plots) {
		createBoxPlot(int1, int2, int3, "Intensity "+folder_name, "{,Ch1,, Ch2,, Ch3,}","Intensity", false, false);
		Plot.show();
		createBoxPlot(area1, area2, area3, "Area "+folder_name, "{,Ch1,, Ch2,, Ch3,}", "Area [Pixel]", false, false);
		Plot.show();
		createFrameGraph(frame_array);
		Plot.show()
	}
	showMessage("ColocJ","Total number of colocalizations: "+area1.length);
	//print("Total Number of Colocalizations: "+area1.length);
}
function no_selection_double() {

	int1 = newArray(0);
	int2 = newArray(0);
	area1 = newArray(0);
	area2 = newArray(0);
	frame_array = newArray(0);	
	
	coloc_folder = getDirectory("Choose a Colocalization directory");
	folder_name = File.getName(coloc_folder);
	datafile = coloc_folder + "double_colocalization/results/coloc_data.csv";
	if (File.exists(datafile) == false){
		showMessage("ColocJ","There was no coloc_data.csv file found in the directory.\nPlease only select directories created by ColocQuant.");
		exit();
	}
	file = File.openAsString(datafile);
	headers = newArray(0);
	LineArray = split(file, "\n");
	DataArray = split(LineArray[0], ",");
	headers = DataArray;
	if(endsWith(headers[4], "1")==true){ch1="Ch"+"1";ch1_int = 1;}
	if(endsWith(headers[4], "2")==true){ch1="Ch"+"2";ch1_int = 2;}
	if(endsWith(headers[8], "2")==true){ch2="Ch"+"2";ch2_int = 2;}
	if(endsWith(headers[8], "3")==true){ch2="Ch"+"3";ch2_int = 3;}
	run("Clear Results");
	Overlay.remove;

	imageID = getImageID();
	size = 3;
	if(max_rib_center || max_rib_edges){
		create_color_ribbon(ch1, ch2, size);
		ribbonID = getImageID();
	}
	setBatchMode(true);
	selectImage(imageID);
	run("Duplicate...", "duplicate");
	copyID = getImageID();
	for (i = 1; i < LineArray.length; i++) {
		DataArray = split(LineArray[i], ",");
		number = parseInt(DataArray[0]);
		mean_x = parseInt(DataArray[1]);  //get coordinates of colocalization
		mean_y = parseInt(DataArray[2]);
		frame = parseInt(DataArray[3]);
		
		//rgb_int = Array.concat(rgb_int,parseFloat(DataArray[3]));
		int1 = Array.concat(int1,parseFloat(DataArray[6]));
		int2 = Array.concat(int2,parseFloat(DataArray[10]));
		area1 = Array.concat(area1,parseFloat(DataArray[7]));
		area2 = Array.concat(area2,parseFloat(DataArray[11]));
		x1 = parseFloat(DataArray[4]);
		x2 = parseFloat(DataArray[8]);
		y1 = parseFloat(DataArray[5]);
		y2 = parseFloat(DataArray[9]);
		frame_array = Array.concat(frame_array, parseInt(DataArray[3]));
		if(max_rib_center){
			selectImage(copyID);
			Stack.setFrame(frame);
			Stack.setChannel(ch1_int);
			//Stack.setPosition(1, 1, frame) //channel, slize, frame
			color1 = getPixel(mean_x, mean_y);
			Stack.setChannel(ch2_int);
			color2 = getPixel(mean_x, mean_y);
			fill_ribbon(color1, color2, ribbonID, size);
		}
		else if(max_rib_edges){
			fill_ribbon(parseFloat(DataArray[6]), parseFloat(DataArray[10]), ribbonID, size);
		}
		point_draw(frame, mean_x, mean_y, number, imageID, true);
		
		for (j = 0; j < 11; j++){
		if(j==0){
		setResult("number", i-1, number+1);	
		}
		else {
		setResult(headers[j], i-1, toString(parseFloat(DataArray[j])));
		}
		}
	}
	setBatchMode(false);
	//testing if no colocalization at all
	if (int1.length < 10 && int1.length != 0) {
		showMessage("ColocJ","Total number of colocalizations: "+area1.length+".\nThe boxplots might not be accurate for a dataset of that size.");
	}
	if (int1.length == 0) {
		showMessage("ColocJ","No colocalization found.\nPlot cannot be created.");
		exit();
	}
	selectImage(imageID);
	Overlay.show;
	if (box_plots) {
		filler = newArray(0);
		createBoxPlot(int1, int2, filler , "Intensity "+folder_name, "{,"+ch1+",, "+ch2+",}","Intensity", ch1, ch2);
		Plot.show();
		createBoxPlot(area1, area2, filler, "Area "+folder_name, "{,"+ch1+",, "+ch2+",}", "Area [Pixel]", ch1, ch2);
		Plot.show();
		createFrameGraph(frame_array);
		Plot.show()
	}
	showMessage("ColocJ","Total number of colocalizations: "+area1.length);
	//print("Total Number of Colocalizations: "+area1.length);
}

function detection() {
	detec_folder = getDirectory("Please select a detection folder");
	coloc_folder = File.getParent(detec_folder);
	roi = false;
	if (selectionType() != -1){roi = true;}
	//if (selectionType() != 2){showMessage("ColocJ","Please only use the polygon selection tool.");}

	id_det = newArray(0);
	x_det = newArray(0);
	y_det = newArray(0);
	frame_det = newArray(0);
	x_values = newArray(0);
	intensity_det = newArray(0);
	size_det = newArray(0);

	
	detection_path = detec_folder + "/results/tracks.mdf";
	if(File.exists(detection_path)==false){
		showMessage("ColocJ", "Please select a detection folder for a specific channel.");
		exit();
	}
	detection_file = File.openAsString(detection_path);
	Lines_mdf = split(detection_file, "\n");
	for (i = 3; i < Lines_mdf.length-1; i=i+2) {
		DataArray = split(Lines_mdf[i], " ");
		DataArray2 = split(Lines_mdf[i+1], " ");
		id = parseInt(DataArray[1]);
		x = DataArray2[2];
		y = DataArray2[3];
		frame = DataArray2[5];
		intensity = DataArray2[7];
		size = DataArray2[8];
		
		if(roi == true){
			if (selectionContains(x, y)){
				id_det = Array.concat(id_det,id);
				x_det = Array.concat(x_det,x);
				y_det = Array.concat(y_det,y);
				frame_det = Array.concat(frame_det,frame);
				intensity_det = Array.concat(intensity_det,intensity);
				size_det = Array.concat(size_det,size);
			}
		}
		if(roi == false){	
			id_det = Array.concat(id_det,id);
			x_det = Array.concat(x_det,x);
			y_det = Array.concat(y_det,y);
			frame_det = Array.concat(frame_det,frame);
			intensity_det = Array.concat(intensity_det,intensity);
			size_det = Array.concat(size_det,size);
		}
	}
	for (z = 0; z < x_det.length; z++) {
		setColor("#ffffff");
		Overlay.drawEllipse(x_det[z], y_det[z], 1, 1);
		Overlay.setPosition(0,1,frame_det[z]);
		Overlay.show;
	}
	create_histogram(intensity_det,"Intensity histogram","Intensity","Count");
	create_histogram(size_det,"Size histogram","Size [pixels]","Count");

	roi_print = "";
	if(roi == true){roi_print = " in ROI";}
	print("/Clear");
	print("detections"+roi_print + ":","\n"+ id_det.length);
	Array.getStatistics(size_det, size_min, size_max, size_mean, size_stdDev);
	print("mean SIZE: "+ size_mean);
	print("standard deviation: "+ size_stdDev);
	print("min: "+size_min+" - max: "+ size_max);
	Array.getStatistics(intensity_det, intensity_min, intensity_max, intensity_mean, intensity_stdDev);
	print("mean INTENSITY: "+ intensity_mean);
	print("standard deviation: "+ intensity_stdDev);
	print("min: "+intensity_min+" - max: "+ intensity_max);

	// output arrays for size and intensity
	Dialog.create("ColocJ");
	Dialog.addMessage("Save number of detections?");
	Dialog.addChoice("Answer:", newArray("Yes","No"));
	Dialog.show();
	choice = Dialog.getChoice();
	if (choice == "Yes") {
		output_path = getDirectory("Where do you want to save the number of detections?");
		file_name = getString("Name of the saved file?", "detections_cell");
		f = File.open(output_path + "/"+file_name+".txt");
		//print(f, "Title: Number of " +  return_value +" colocalizations per frame");
		print(f, "#detections"+roi_print + ":" +id_det.length);
		if (roi == true) {
			print(f, "# in selected ROI");
		}
		if (roi == false) {
			print(f, "#in entire image");
		}
		print(f,"#mean SIZE: "+ size_mean);
		print(f,"#standard deviation: "+ size_stdDev);
		print(f,"#min: "+size_min+" - max: "+ size_max);
		print(f,"#mean INTENSITY: "+ intensity_mean);
		print(f,"#standard deviation: "+ intensity_stdDev);
		print(f,"#min: "+intensity_min+" - max: "+ intensity_max);
		print(f, "Number, Intensity, Size ");
		for (i = 0; i < id_det.length; i++) {
			print(f, id_det[i]+","+ intensity_det[i]+","+size_det[i]);
		}
		File.close(f);
	}
	
}
function create_histogram(array, title, xtitle, ytitle){
	Plot.create(title, xtitle, ytitle);
	Plot.setFrameSize(510, 250);
	Array.getStatistics(array, min, max, mean, stdDev);
	bin_width = (max - min) / 100;
	Plot.setColor("#000000", "#4195cb");
	Plot.addHistogram(array, bin_width);
	Plot.show();
}

function createFrameGraph(frame_array) {
	all_frames = frame_array;
	x_values = newArray(0);
	Array.getStatistics(all_frames, min, max, mean, stdDev);
	count_frames = newArray(max);
	for (i = 0; i < all_frames.length; i++) {
		frame = all_frames[i];
		count_frames[frame-1] = count_frames[frame-1] + 1; 
	}
	for (j = 1; j <= max; j++) {
		x_values = Array.concat(x_values,j);
	}
	xValues = x_values;
	yValues = count_frames;
	output_framecounts(xValues, yValues,"colocalizations");
	Plot.create("Colocalizations per Frame", "Frame", "Number of colocalizations");
	Plot.setFontSize(14);
	Plot.setColor("blue","#bbbbff");
	Plot.add("separatedbars", xValues, yValues);
	Plot.setFrameSize(510, 250);
	Plot.setLineWidth(1);
	Array.getStatistics(yValues, min, max, mean, stdDev);
	Plot.setLimits(0, xValues.length +1 , 0, max+1);
}

function output_framecounts(frames, numbers, det_or_coloc){
	Dialog.create("ColocJ");
	Dialog.addMessage("Save number of "+det_or_coloc+" per frame?");
	Dialog.addChoice("Answer:", newArray("Yes","No"));
	Dialog.show();
	choice = Dialog.getChoice();
	if (choice == "Yes") {
		output_path = getDirectory("Where do you want to save the number of "+det_or_coloc+"?");
		while(File.exists(output_path + "/"+det_or_coloc+"_per_frame.csv")){
			showMessage("ColocJ", "A file with the same name already exists in the chosen directory.\nPlease choose a different directory.");
			output_path = getDirectory("Where do you want to save the number of "+det_or_coloc+"?");
			}
		f = File.open(output_path + "/"+det_or_coloc+"_per_frame.csv");
		//print(f, "Title: Number of " +  return_value +" colocalizations per frame");
		print(f, "Frame,Number of "+ det_or_coloc);
		for (i = 0; i < xValues.length; i++) {
			print(f, frames[i]+","+ numbers[i]);
		}
		File.close(f);
	}
}
function createBoxPlot(array1, array2, array3, plot_title, xtitle, ytitle, ch1, ch2) {
	Plot.create(plot_title, xtitle, ytitle);
	Plot.setFrameSize(510, 250);
	if (array3.length!=0) {
		max1 = drawPlots(array1, 1, "#ffcccc");
		max2 = drawPlots(array2, 3, "#ccffcc");
		max3 = drawPlots(array3, 5, "#ccccff");
		upper_max = maxOf(max1, maxOf(max2, max3)); 
		Plot.setLimits(0, 6, 0, (upper_max*1.05));
	}
	else {
		if(ch1=="Ch1"){max1 = drawPlots(array1, 1, "#ffcccc");}
		if(ch1=="Ch2"){max1 = drawPlots(array1, 1, "#ccffcc");}
		if(ch2=="Ch2"){max2 = drawPlots(array2, 3, "#ccffcc");}
		if(ch2=="Ch3"){max2 = drawPlots(array2, 3, "#ccccff");}
		upper_max = maxOf(max1, max2); 
		Plot.setLimits(0, 4, 0, (upper_max*1.05));
	}


}
function drawPlots(array, number, color) {
	Array.getStatistics(array, min, max, mean, stdDev);
	quarts = calc_quarts_median(array);
	quart_low = quarts[0];
	quart_high = quarts[1];
	median = quarts[2];
	min_whisker = quarts[3];
	max_whisker = quarts[4];
	Plot.setLineWidth(2);
   	Plot.setColor("black", color);
	Plot.drawShapes("boxes width=40", number, min_whisker, quart_low, median, quart_high, max_whisker);
	Plot.drawLine(number-0.05, max_whisker, number+0.05, max_whisker);
	Plot.drawLine(number-0.05, min_whisker, number+0.05, min_whisker);
	return max_whisker;
}	
//input array, output upper and lower quartile border
function calc_quarts_median(array) {
	Array.getStatistics(array, min, max, mean, stdDev);
	sorted = Array.sort(array);
	//Array.print(sorted);
	length = lengthOf(array);
	median = sorted[round(length*0.5)-1];
	quart_low = sorted[round(length*0.25)];
	quart_high = sorted[round(length*0.75)-1];
	min_whisker = sorted[round(length*0.025)];
	max_whisker = sorted[round(length*0.975)-1];
	//print("length: "+length, "\nlength*0.25 :"+length*0.25+" --> "+round(length*0.25), "\nlength*0.75: "+length*0.75+" --> "+round(length*0.75));
	//print("Median: "+median);
	//print("quart_low: "+quart_low);
	//print("quart_high: "+quart_high);
	a = newArray(quart_low, quart_high, median, min_whisker, max_whisker);
	//Array.print(a);
	return a;

}
function point_draw(frame, x, y, number,  imageID, text) {
	selectImage(imageID);
	setColor("#ffff00");
	setLineWidth(1);
	width = height = 8;
	Overlay.drawEllipse(x-(width/2), y-(height/2), width, height);
	Overlay.setPosition(0,1,frame); //syntax here is (channel, slize, frame), a 0 stands for all
	if(text==true){
	Overlay.drawString(number+1, x, y);
	Overlay.setPosition(0,1,frame);
	}
}
function triangle_draw(frame, x1, x2, x3, y1, y2, y3, number, imageID) {
	selectImage(imageID);
	setColor("#ffff00");
	setLineWidth(1);
	Overlay.drawLine(x1, y1, x2, y2);
	Overlay.setPosition(0,1, frame);
	Overlay.drawLine(x2, y2, x3, y3);
	Overlay.setPosition(0,1, frame);
	Overlay.drawLine(x3, y3, x1, y1);
	Overlay.setPosition(0,1, frame);
}


function create_maxwell_triangle(size) {
	width = 295*size;
	height = 256*size;
	setBatchMode(true);
	newImage("Colour Profile", "RGB", width, height, 1);
	setColor(0,0,0);
	//setLineWidth(size);
	Rx = width;
	Ry = 0;
	Gx = width/2;
	Gy = height;
	Bx = 0;
	By = 0;
	//drawLine(Rx, Ry, Gx, Gy); // R -> G
	//drawLine(Gx, Gy, Bx, By); // G -> B
	//drawLine(Bx, By, Rx, Ry); // B -> R
	setLineWidth(1);
	xcoord = newArray(Rx, Gx, Bx);
	ycoord = newArray(Ry, Gy, By);
	makeSelection("polygon", xcoord, ycoord); // selects triangle
	for (x = 0; x < width; x++) {
		for (y = 0; y < height; y++) {
			if (selectionContains(x, y)){
				rgb = xy2rgb(x,y, width, height);
				r = rgb[0];
				g =  rgb[1];
				b =  rgb[2];
				max = maxOf(r, maxOf(g, b));
				multiplier = 255/max;
				setColor(r*multiplier, g*multiplier, b*multiplier);
				drawLine(x, y, x, y);
			}
		}
	}
	setBatchMode(false);
}
function fill_maxwell(x, y, int1, int2, int3, imageID, maxwellID, width, height, frame) {
	setColor("black");
	red = int1;
	green = int2;
	blue = int3;
	xy = rgb2xy(red, green, blue, width, height);
	selectImage(maxwellID);
	drawOval(xy[0]-4/2, xy[1]-4/2, 4, 4);
}
function create_color_ribbon(ch1, ch2, size) {
	height = 40*size;
	width = 255*size;
	setBatchMode(true);
	newImage("Colour Profile", "RGB", width, height, 1);
	setColor(0,0,0);
	for (x = 0; x < width; x++) {
		if (ch1=="Ch1" && ch2=="Ch2") {r = x/size; g = 255-x/size; b = 0;}
		if (ch1=="Ch1" && ch2=="Ch3") {r = x/size; g = 0; b = 255-x/size;}
		if (ch1=="Ch2" && ch2=="Ch3") {r = 0; g = x/size; b = 255-x/size;}
		max = maxOf(r, maxOf(g, b));
		multiplier = 256/max;
		setColor(r*multiplier, g*multiplier, b*multiplier);
		for (y = 0; y < height; y++) {
			drawLine(x, y, x, y);
		}
	}
	setBatchMode(false);
}
function fill_ribbon(int1, int2, maxwellID, size) {
	setColor("black");
	color1 = int1;
	color2 = int2;
	sum = color1+color2;
	color1 = (color1/sum)*255;
	ran = random;
	if(ran<0.5){ran = ran+0.05;}
	if(ran>=0.5){ran = ran-0.05;}
	y = ran*40*size;
	x = color1*size;
	selectImage(ribbonID);
	drawOval(x-4/2, y-4/2, 4, 4);
}
function xy2rgb(x, y, width, height) {
	a = (x-y*(width/(height*2)))/(width-((y/height)*width));
	g = y;
	r = -(a*(height-y-(height-y)*a))/(a-1);
	b = height-y-(height-y)*a;
	return newArray(r, g, b);
}

function rgb2xy(r, g, b, width, height) {
	rgb = convert255(r,g,b);
	r = rgb[0];
	g = rgb[1];
	b = rgb[2];
	if (r==0 && b == 0) {
		x = height/2;
	}
	else {
		x = (g/255)*(width/2)+(r/(r+b))*(width-((g/255)*(width)));
	}
	y = g*(height/256);
	return newArray(x,y);
}

function convert255(r, g, b) {
	if(r < 0){r = 0 ;}
	if(g < 0){g = 0 ;}
	if(b < 0){b = 0 ;}
	sum = r+g+b;
	factor = 255/sum;
	r = r*factor;
	g = g*factor; 
	b = b*factor;
	return newArray(r, g, b);
}

macro "show_overlay [s]"{
	run("Show Overlay");
}
macro "hide_overlay [h]"{
	run("Hide Overlay");
}
macro "ch1 [1]"{
	Stack.getActiveChannels(string);
	if(startsWith(string, "100")){Stack.setActiveChannels("000");}
	if(startsWith(string, "000")){Stack.setActiveChannels("100");}
	if(startsWith(string, "110")){Stack.setActiveChannels("010");}	
	if(startsWith(string, "010")){Stack.setActiveChannels("110");}
	if(startsWith(string, "101")){Stack.setActiveChannels("001");}	
	if(startsWith(string, "001")){Stack.setActiveChannels("101");}
	if(startsWith(string, "111")){Stack.setActiveChannels("011");}	
	if(startsWith(string, "011")){Stack.setActiveChannels("111");}
}
macro "ch2 [2]"{
	Stack.getActiveChannels(string);
	if(startsWith(string, "100")){Stack.setActiveChannels("110");}
	if(startsWith(string, "000")){Stack.setActiveChannels("010");}
	if(startsWith(string, "110")){Stack.setActiveChannels("100");}	
	if(startsWith(string, "010")){Stack.setActiveChannels("000");}
	if(startsWith(string, "101")){Stack.setActiveChannels("111");}	
	if(startsWith(string, "001")){Stack.setActiveChannels("011");}
	if(startsWith(string, "111")){Stack.setActiveChannels("101");}	
	if(startsWith(string, "011")){Stack.setActiveChannels("001");}
}
macro "ch3 [3]"{
	Stack.getActiveChannels(string);
	if(startsWith(string, "100")){Stack.setActiveChannels("101");}
	if(startsWith(string, "000")){Stack.setActiveChannels("001");}
	if(startsWith(string, "110")){Stack.setActiveChannels("111");}	
	if(startsWith(string, "010")){Stack.setActiveChannels("011");}
	if(startsWith(string, "101")){Stack.setActiveChannels("100");}	
	if(startsWith(string, "001")){Stack.setActiveChannels("000");}
	if(startsWith(string, "111")){Stack.setActiveChannels("110");}	
	if(startsWith(string, "011")){Stack.setActiveChannels("010");}
}
var hidden = false;
macro "hide_number [n]" {
	imageID = getImageID()
	if(nResults == 0) {
		showMessage("ColocJ","A results window needs to be open to use this shortcut [n].");
	}
	else {
		hidden = hide_number(imageID, hidden);
	}
}
function hide_number(imageID, hidden) {
	Overlay.remove;	
	for (i = 0; i < nResults; i++) {
		x = getResult("X_mean", i);
		y = getResult("Y_mean", i);
		x1 = getResult("X_ch1", i);
		y1 = getResult("Y_ch1", i);
		x2 = getResult("X_ch2", i);
		y2 = getResult("Y_ch2", i);
		x3 = getResult("X_ch3", i);
		y3 = getResult("Y_ch3", i);
		frame = getResult("frame", i);
		number = getResult("number", i);
		if(hidden == true && return_value!="detection") {
			text = true;
			point_draw(frame, x, y, number-1,  imageID, text);
		}
		else if(return_value!="detection"){
			text = false;
			point_draw(frame, x, y, number,  imageID, text);
		}
		if(return_value=="triple"){
			triangle_draw(frame, x1, x2, x3, y1, y2, y3, number, imageID);
		}
		
}
	Overlay.show;
	if(hidden == true) {hidden = false;}
	else if(hidden == false) {hidden = true;}
	return hidden;
}
var lower_threshold = newArray();
var upper_threshold = newArray();
macro "grayscale_movie [m]"{
		/*/
	This version of the grayscale macro works on a single image. 
	It converts the ovderlapping ROI's to a binary picture of the overlap.
	Selecting a threshold, so that only 1 item is marked with an ROI is not allowed.
	/*/

	showMessageWithCancel("Grayscale macro [m]","Do you wish to start the grayscale macro?\nThis will reset the ROI manager.");
	roiManager("Reset");
	// input should be a composite image
	input_path = File.openDialog("Choose a composite image to open");
	open(input_path);
	getDimensions(width, height, channels, slices, frames);
	if(channels ==1){
		showMessage("Grayscale macro [m]","This is not a composite image.\nThis macro can only take composite (multi-channel) images as input.");
		exit;
	}
	lower_threshold = newArray(channels);
	upper_threshold = newArray(channels);
	input_title=getTitle();
	showMessageWithCancel("Grayscale macro [m]","An image with "+channels+" channels and "+slices+" slice(s) was opened. Continue?");
	close(input_title);
	
	//choose and create an output directory
	// loop creating ROIs for each channel
	for (slice = 1; slice <= slices; slice++) {//repeat steps for every slice
		if (slice != 1) {setBatchMode("hide");}
		open(input_path);
		run("Make Substack...", " slices="+slice);//substack with one slice at a time
		substack_title = getTitle();
		run("Split Channels");
		for (channel = 1; channel < channels + 1; channel++) {
			create_ROI(channel, input_title, slice);
		}
		depth=1;
		if(slice == 1){
			newImage("grayscale_movie.tif", "16-bit", width, height, depth);
		}
		else {
			newImage("binary_overlap_s"+slice+".tif", "16-bit", width, height, depth);
		}
		new_id = getImageID();
		for (i = 1; i < channels; i++) {
			no_overlay = false;
			if(i == 1 && roiManager("count")!=channels){//break if no overlay was found for each channel
				no_overlay = true;
				break:
				}
			roiManager("deselect");
			roiManager("select",newArray(0,1));//select channel 1 and 2 roi
			roiManager("and");//keeps only the overlap
			if (selectionType() == -1){
				roiManager("delete");
				Overlay.remove;//removes the currently still active roi overlay
				no_overlay = true;
				break;
			}
			roiManager("add");// adds the overlap
			roiManager("select",newArray(0,1))
			roiManager("delete");//deletes the sig rois
		}
		
		// turn the overlap roi in a binary
		selectImage(new_id);
		if (no_overlay == false){//only do this when a final overlap roi is present
			roiManager("select",0);
			roiManager("Set Fill Color", "white");
			run("Flatten");
			rename("new_slice");
			if(slice == 1){
				rename("grayscale_movie.tif");
			}
			run("Select None");//remvoes selection boundaries form image
		}
		else {
			run("RGB Color");//transform 16-bit into RGB
			rename("new_slice");
			if(slice == 1){
				rename("grayscale_movie.tif");
			}
			run("Select None");//remvoes selection boundaries form image
		}
		if(slice != 1){//add new image to stack
			run("Concatenate...", " title=grayscale_movie.tif image1=grayscale_movie.tif image2=new_slice");
		}
		//saveAs("Tiff", dirOut2 +"binary_overlap"); 
		close("/Others");
		if (roiManager("count")!= 0){
			roiManager("delete");
		}
		}
	setBatchMode("show");
	function create_ROI(channel, input_title, slice) {
		no_roi = false;//test variable 
		if(slice==1){threshold_test = true;}//only repeat in first run
		else{threshold_test = false;}
		//duplicate the C1-image
		selectImage("C"+channel+"-" + substack_title);
		run("Duplicate...", "title=C"+channel+"-Duplicate");
		if(threshold_test) {
			//only ask for threshold in first run
			getRawStatistics(nPixels, mean, min, max, std, histogram);
			//ask user for thresholds for channel one
			Dialog.create("ColocJ");
			Dialog.addMessage("Please set the threshold for Ch"+ channel +" creating a grayscale movie.")
			Dialog.addNumber("Lower threshold", min);
			Dialog.addNumber("Upper threshold", 100000);
			Dialog.show();
			lower_thr_value = Dialog.getNumber();
			upper_thr_value = Dialog.getNumber();
			lower_threshold[channel-1] = lower_thr_value;
			upper_threshold[channel-1] = upper_thr_value;
			}
		//threshold image
		setThreshold(lower_threshold[channel-1], upper_threshold[channel-1]);
		setOption("BlackBackground", false);
		run("Convert to Mask");
		run("Make Binary");
		
		//find all particles in image
		run("Analyze Particles...", "  show=Nothing add");
		roiManager("deselect");// deselects so that next commands affect all rois
		count_rois = roiManager("count");
		new_rois = newArray(count_rois - (channel-1));
		for (i = 0; i < count_rois-(channel-1); i++) {
			new_rois[i] = i+(channel-1);
			}
		roiManager("show none");
		roiManager("select",new_rois);// selects only the new rois
		if(lengthOf(new_rois)==0){//if no roi in channel, no overlap in this slice
			if(roiManager("count")!=0){
				roiManager("deselect");
				roiManager("delete");
				}
			if(threshold_test==false){break};//only break, if its not the first run
			else {
				no_roi = true;
			}
		}
		if(no_roi == false){//skip these steps if no roi was selected
			if(lengthOf(new_rois)!=1){//only combine rois, when there are multiple
				roiManager("combine");//uses the union operator to combine all rois
			}
			
				roiManager("add");
				roiManager("delete");// deletes the single rois
				roiManager("select", channel-1);
		}
		if(threshold_test){//only ask for threshold in first run
			Dialog.create("ColocJ");
			Dialog.addMessage("Use this threshold?");
			Dialog.addChoice("Answer:", newArray("Yes","No"));
			Dialog.show();
			choice = Dialog.getChoice();
			if(choice == "Yes"){
				threshold_test = false;
				close("Mask of C"+channel+"-Duplicate");
			}
			else{
				if(no_roi == false){
					roiManager("select", channel-1);
					roiManager("delete");
				}
				close();
				close("Mask of C"+channel+"-Duplicate");
				create_ROI(channel, input_title, slice);
				}
			}
	}
}
var detection_num = "";

macro "detection_ch1 [y]" {
	imageID = getImageID();
	if (detection_num == "1"){
			hide_number(imageID, true);
			detection_num = "";
	}
	else {
		if (detection_num == "") {
		show_detection(1);
		detection_num = "1";
		}
		if (detection_num == "2" || detection_num == "3") {
		hide_number(imageID, true);
		show_detection(1);
		detection_num = "1";
		}
	}
}
macro "detection_ch2 [x]"  {
	imageID = getImageID();
	if (detection_num == "2"){
			hide_number(imageID, true);
			detection_num = "";
	}
	else {
		if (detection_num == "") {
		show_detection(2);
		detection_num = "2";
		}
		if (detection_num == "1" || detection_num == "3") {
		hide_number(imageID, true);
		show_detection(2);
		detection_num = "2";
		}
	}
}
macro "detection_ch3 [c]"{
	imageID = getImageID();
	if (detection_num == "3"){
			hide_number(imageID, true);
			detection_num = "";
	}
	else {
		if (detection_num == "") {
		show_detection(3);
		detection_num = "3";
		}
		if (detection_num == "2" || detection_num == "1") {
		hide_number(imageID, true);
		show_detection(3);
		detection_num = "3";
		}
	}
}

function show_detection(channel) {
	if (coloc_folder == ""){
		coloc_folder = getDirectory("Please select a colocalization folder for this shortcut to work");
	}

	detection_path = coloc_folder + "/detection_ch"+channel+"/results/tracks.mdf";
	if(File.exists(detection_path)==false){
		showMessage("ColocJ", "No detection available for this channel.");
		exit();
	}
	detection_file = File.openAsString(detection_path);
	Lines_mdf = split(detection_file, "\n");
	for (i = 3; i < Lines_mdf.length-1; i=i+2) {
		DataArray = split(Lines_mdf[i], " ");
		DataArray2 = split(Lines_mdf[i+1], " ");
		id = parseInt(DataArray[1]);
		x = DataArray2[2];
		y = DataArray2[3];
		frame = DataArray2[5];
		setColor("#ffffff");
		Overlay.drawEllipse(x, y, 1, 1);
		Overlay.setPosition(0,1,frame);
		Overlay.show;
	}
}
macro "detection_framewise [d]"{
	detec_folder = getDirectory("Please select a detection folder for this shortcut to work");
	roi = false;
	if (selectionType() != -1){roi = true;}
	//if (selectionType() != 2){showMessage("ColocJ","Please only use the polygon selection tool.");}

	id_det = newArray(0);
	x_det = newArray(0);
	y_det = newArray(0);
	frame_det = newArray(0);
	x_values = newArray(0);

	
	detection_path = detec_folder + /results/tracks.mdf";
	detection_file = File.openAsString(detection_path);
	Lines_mdf = split(detection_file, "\n");
	for (i = 3; i < Lines_mdf.length-1; i=i+2) {
		DataArray = split(Lines_mdf[i], " ");
		DataArray2 = split(Lines_mdf[i+1], " ");
		id = parseInt(DataArray[1]);
		x = DataArray2[2];
		y = DataArray2[3];
		frame = DataArray2[5];

		if(roi == true){
			if (selectionContains(x, y)){
				id_det = Array.concat(id_det,id);
				x_det = Array.concat(x_det,x);
				y_det = Array.concat(y_det,y);
				frame_det = Array.concat(frame_det,frame);
			}
		}
		if(roi == false){	
			id_det = Array.concat(id_det,id);
			x_det = Array.concat(x_det,x);
			y_det = Array.concat(y_det,y);
			frame_det = Array.concat(frame_det,frame);
		}
	}
	Array.getStatistics(frame_det, min, max, mean, stdDev);
	count_frames = newArray(max);
	
	for (i = 0; i < frame_det.length; i++) {
		frame = frame_det[i];
		count_frames[frame-1] = count_frames[frame-1] + 1; 
		}
	for (j = 1; j <= max; j++) {
			x_values = Array.concat(x_values,j);
		}
	xValues = x_values;
	yValues = count_frames;
	output_framecounts(xValues, yValues,"detections");
	Plot.create("Detections per Frame", "Frame", "Number of detections");
	Plot.setFontSize(14);
	Plot.setColor("blue","#bbbbff");
	Plot.add("separatedbars", xValues, yValues);
	Plot.setFrameSize(510, 250);
	Plot.setLineWidth(1);
	Array.getStatistics(yValues, min, max, mean, stdDev);
	Plot.setLimits(0, xValues.length +1 , 0, max+1);
}
