/**
 * This macro helps the user to set ROIs on images in a lif file.
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
function processImage(name) {
	waitForUser("Select ROI");
	roiManager("add");
	roiManager("select", roiManager("count") - 1);
	roiManager("save selected", dir + "/roi/" + name + ".roi");
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
if (File.exists(dir+ "/roi") == false) {
	File.makeDirectory(dir+ "/roi");
}

// initialize Bio-Formats and process lif file.
run("Bio-Formats Macro Extensions");
Ext.setId(file);
Ext.getSeriesCount(seriesCount);
for (s=0; s<seriesCount; s++) {
	name = openImage(file,s);
	processImage(name, s);
	close("*");
}
Ext.close();
