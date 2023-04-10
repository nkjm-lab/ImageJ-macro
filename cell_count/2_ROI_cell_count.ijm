/**
 * This macro counts the GFP positive cells in images from lif file.
 * Run 1_ROI_cell_count.ijm first to define ROIs in the images.
 */

/*
 * open image with bio formats
 * @param file path to lif file
 * @param index indice of image to open
 * @return window title of current image
 */
function openImage(file,index){
	run("Bio-Formats Importer", "series_list=" + (index+1) + " open=[" + file + "] autoscale color_mode=Composite view=Hyperstack stack_order=XYCZT");
	return getInfo("window.title");
}

/*
 * process opened image
 * @param name window title of current image
 */
function processImage(name, index) {
	// draw ROI on duplicated image
	selectWindow(name);
	run("Duplicate...", "title=DUP duplicate");
	selectWindow("DUP");
	run("RGB Color");
	setForegroundColor(255, 255, 255);
	setBackgroundColor(0, 0, 0);
	roiManager("open", dir + "/roi/" + name + ".roi");
	roiManager("select", roiManager("count") - 1);
	roiManager("draw");

	// Select GFP channel of current image
	selectWindow(name);
	run("Split Channels");
	selectWindow("C2-" + name );
	// filter image
    run("Gaussian Blur...","radius=2");
    // use auto thrshold to binarize GFP channel
	run("Auto Threshold", "method=MaxEntropy white");
	run("Convert to Mask");
	// remove noise from binary image
	run("Open");
	run("Watershed");
	// select ROI
	roiManager("select", roiManager("count") - 1);
	// count cells using analyze particles
	run("Analyze Particles...", "size=" + "10-Infinity" + " pixel show=Masks summarize");
	// create ROI from the result of analyze particles
	selectWindow("Mask of " + "C2-" + name );
	run("Create Selection");
	roiManager("Add");
	// draw counted cells on duplicated image
	selectWindow("DUP (RGB)");
	setForegroundColor(255, 0, 0);
	roiManager("Select", roiManager("count") - 1);
	roiManager("draw");
	// save as tiff
	saveAs("Tiff", dir+"/result/Count_" +name);
	// wait for imagej to save the image
	wait(500);
}

// choose file
file = File.openDialog("Choose a .lif file");
if(endsWith(file, ".lif") == false){
	exit("This macro can only process .lif file.");
}

// set output directory
dir = replace(file, ".lif", "");
if (File.exists(dir) == false) {
	File.makeDirectory(dir);
}
if (File.exists(dir+ "/result") == false) {
	File.makeDirectory(dir+ "/result");
}

// initialize Bio-Formats and process lif file.
setBatchMode(true);
run("Bio-Formats Macro Extensions");
Ext.setId(file);
Ext.getSeriesCount(seriesCount);
for (s=0; s<seriesCount; s++) {
	name = openImage(file,s);
	processImage(name, s);
	close("*");
}
Ext.close();

// save counts
selectWindow("Summary");
saveAs("Results", dir + "/result/Count.csv");