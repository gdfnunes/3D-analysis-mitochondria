/* 
 *  Calculate_mitochondria_3D
 *  This macro will take a directory of TIFFs
 *  	Process the image with a median filter
 *  	Identify the mitochondria (in the green channel)
 *  	Identify the organelle of interest (in the red channel)
 *  	Calculate the volume and sphericity of mitochondria and their distance to the organelle of interest
 *  	Export the results to txt files (1 per TIFF file). You can then do the post processing, like filtering the results according to a specific distance.
 *  Macro by Gustavo Della Flora Nunes
*/

// Select a folder with your TIFF files and an empty folder to output your results. 
INPUT_DIR=getDirectory("Select the input directory. Should contain only the tiff files!");
OUTPUT_DIR=getDirectory("Select the output directory. Different from input!");

Shape_measurment(INPUT_DIR); 

// Function to run the analysis 
function Shape_measurment(INPUT_DIR) {
	list = getFileList(INPUT_DIR);
// For each file in the directory
	for (i=0; i<list.length; i++) {
		open(INPUT_DIR+list[i]);
// Set the scale. Adjust it according to your files.
		run("Set Scale...", "distance=10 known=1 pixel=1 unit=micron global");
		run("Split Channels");
// Select the channel with the organelle of interest. In this case it is in the red channel
		selectWindow(list[i]+" (red)");
// Run a median filter. Adjust the cpu numbers to your computer!
		run("3D Fast Filters","filter=Median radius_x_pix=2.0 radius_y_pix=2.0 radius_z_pix=2.0 Nb_cpus=4");
		selectWindow("3D_Median");
// Use an hysteresis thresholding method to identify the organelle. Optimize the high and low values!
		run("3D Hysteresis Thresholding", "high=50 low=20");
// Add the selection to the 3D ROI Manager
		run("3D Manager");
		selectWindow("3D_Median");
		Ext.Manager3D_AddImage();
// Select the channel with the mitochondria. In this case it is in the green channel
		selectWindow(list[i]+" (green)");
		selectWindow("3D_Median");
		close();
// Run a median filter. Adjust the cpu numbers to your computer!
		run("3D Fast Filters","filter=Median radius_x_pix=2.0 radius_y_pix=2.0 radius_z_pix=2.0 Nb_cpus=4");
		selectWindow("3D_Median");
// Run an 3D iterative thresholding method to identify each mitochondrion
		run("3D Iterative Thresholding", "min_vol_pix=20 max_vol_pix=700 min_threshold=0 min_contrast=0 criteria_method=ELONGATION threshold_method=STEP segment_results=All value_method=10");
// Create a tif file to export 
		f=File.open(OUTPUT_DIR+"Quantification_"+list[i]+".txt");
		selectWindow("draw");
		Ext.Manager3D_AddImage();
		Ext.Manager3D_Count(nb_obj);
		Ext.Manager3D_Measure3D(0,"Vol",vol);
		print(f,"Distance \t Volume \t Compactdness \t \t Volume of organele \t"+vol+"\n");
// Calculate the Distance, volume and sphericity of each mitochondrion 
		for (j=1; j<nb_obj-1; j++) {
			Ext.Manager3D_Dist2(0,j,"bb",dist);
			Ext.Manager3D_Measure3D(j,"Vol",volume);
			Ext.Manager3D_Measure3D(j,"Comp",compactdness);
// Export to the txt file
			print(f,dist+"\t"+volume+"\t"+compactdness+"\n");
			}
		File.close(f)
		Ext.Manager3D_Close();
		while (nImages>0) {
			selectImage(nImages);
			close();
		}
	} 
}
// Show a completion message when analysis is finished
showMessage("Your analysis is complete and results were saved to "+OUTPUT_DIR);