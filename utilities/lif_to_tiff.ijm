/**
 * This macro extracts images from a lif file and saves as tiff.
 */
 
/*
 * open image with bio formats
 * @param file path to lif file
 * @param index index of image to open
 */
function openImage(file,index){
	run("Bio-Formats Importer", "series_list=" + (index+1) + " open=[" + file + "] autoscale color_mode=Composite view=Hyperstack stack_order=XYCZT");
}

/*
 * process opened image
 * @param index series index of opened image
 * @param isScaleBar add scale bar if true
 */
function processOpenImage(index,isScaleBar){
	//get image info from bio formats
	Ext.setSeries(index);
	Ext.getSizeC(sizeC);
	Ext.getSizeZ(sizeZ);
	Ext.getPixelsPhysicalSizeX(sizePX);
	Ext.getSeriesName(name);
	//make output directory
	name=replace(name, "/", "-"); // for tile scan images
	outdir=dir+File.separator + name;
	File.makeDirectory(outdir);
	//set zstack projection
	if (sizeZ>1){
		run("Z Project...", "projection=[Max Intensity]");
		name="MAX_"+name;
	}

	//save composite image
	Stack.setDisplayMode("composite");
	run("RGB Color");
	if (isScaleBar) {
		width=addScaleBar(sizePX);
		saveAs("Tiff", outdir+File.separator+name+"_composite_"+width+"um");
	} else {
		saveAs("Tiff", outdir+File.separator+name+"_composite");
	}
	close();
	//save each channel
	run("Split Channels");
	for (i=sizeC;i>0;i--){
		run("RGB Color");
		if (isScaleBar) {
			width=addScaleBar(sizePX);
			saveAs("Tiff", outdir+File.separator+name+"_C"+i+"_"+width+"um");
		} else {
			saveAs("Tiff", outdir+File.separator+name+"_C"+i);
		}
		close();
	}
}

/*
 * add scale bar to open image
 * @param sizePX physical size of x-axis
 * @return width of scale bar
 */
function addScaleBar(sizePX){
	scaleSets = newArray(1000, 500, 250, 200, 100, 50, 25, 20, 10, 5);
	width = sizePX*1000/5;
	for (i = 0; i < lengthOf(scaleSets); i++) {
		if (width >= scaleSets[i]){
			width = scaleSets[i];
            break;
		}
	}
	run("Scale Bar...", "width="+width+" height="+ width/20 +" color=White background=None location=[Lower Right] bold hide");
	return width
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
// setting 
Dialog.create("Setting");
Dialog.addCheckbox("Add scale bars", true);
Dialog.show();
isScaleBar = Dialog.getCheckbox();

// initialize Bio-Formats and process lif file.
run("Bio-Formats Macro Extensions");
Ext.setId(file);
Ext.getSeriesCount(seriesCount);
setBatchMode(true);
for (s=0; s<seriesCount; s++) {
	openImage(file,s);
	processOpenImage(s,isScaleBar);
	close("*");
}
Ext.close();
