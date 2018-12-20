#include "lodepng.h"
#include <iostream>
#include <vector>
#include <chrono>

using namespace std::chrono;
using namespace std;
typedef unsigned char uchar;

int main()
{
	time_point<steady_clock> time_a = high_resolution_clock::now();
	vector<uchar> image;
	unsigned width, height;
	string image_filename = "test_image.png";
	unsigned exit_code = lodepng::decode(image, width, height, image_filename);

	if (exit_code != 0) {
		cout << "Error opening image " << image_filename << " with the code " << exit_code << ": " << lodepng_error_text(exit_code) << endl;
		exit(exit_code);
	}
	else {
		cout << "Image loaded, size: " << image.size() << " bytes" << endl;
	}
	// Pixels are in 1-D vector, 4 bytes, 4 channels, RGBARGBARGBA

	vector<uchar> red;
	vector<uchar> green;
	vector<uchar> blue;

	for (size_t i = 0; i < image.size(); i += 4) {
		red.push_back(image[i]);
		green.push_back(image[i + 1]);
		blue.push_back(image[i + 2]);
	}

	cout << "Finished preparing channels" << endl;

	vector<uchar> gray;

	time_point<steady_clock> time_b = high_resolution_clock::now();

	for (int i = 0; i < red.size(); i++) {
		double red_val = 0.2125 * red[i];
		double green_val = 0.7154 * green[i];
		double blue_val = 0.0721 * blue[i];

		double gray_val = red_val + green_val + blue_val;

		gray.push_back((uchar)gray_val);
	}

	time_point<steady_clock> time_c = high_resolution_clock::now();

	cout << "Finished creating image" << endl;

	string out_filename = "result_image.png";
	exit_code = lodepng::encode(out_filename, gray, width, height, LCT_GREY);
	if (exit_code != 0) {
		cout << "Error saving file " << out_filename << " with the code " << exit_code << ": " << lodepng_error_text(exit_code) << endl;
		exit(exit_code);
	}
	else {
		cout << "Successfully saved file " << out_filename << endl;
	}
	time_point<steady_clock> time_d = high_resolution_clock::now();

	cout << "TOTAL TIME: " << duration_cast<microseconds>(time_d - time_a).count() << " mcs." << endl;
	cout << "CALCULATION TIME: " << duration_cast<microseconds>(time_c - time_b).count() << " mcs." << endl;
}