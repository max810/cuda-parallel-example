#include "cuda_runtime.h"
#include "device_launch_parameters.h"
#include <stdio.h>
#include <time.h>
#include "lodepng.h"
#include <vector>
#include <iostream>
#include <chrono>
using namespace std;
using namespace chrono;
typedef unsigned char uchar;

__global__ void make_gray(const uchar *r, const uchar *g, const uchar *b, size_t num_pixels, uchar *gray) {
	int i = blockIdx.x * blockDim.x + threadIdx.x;

	if (i > num_pixels) {
		return;
	}

	double red_val = 0.2125 * r[i];
	double green_val = 0.7154 * g[i];
	double blue_val = 0.0721 * b[i];

	double gray_val = red_val + green_val + blue_val;

	gray[i] = gray_val;
}

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

	size_t num_pixels = red.size();
	int threads_per_block = 512;
	int total_blocks = ((num_pixels + threads_per_block - 1) / threads_per_block);

	uchar *d_red, *d_green, *d_blue, *d_gray;

	cudaMallocManaged(&d_red, num_pixels);
	cudaMallocManaged(&d_green, num_pixels);
	cudaMallocManaged(&d_blue, num_pixels);
	cudaMallocManaged(&d_gray, num_pixels);

	cudaMemcpy(d_red, red.data(), num_pixels, cudaMemcpyKind::cudaMemcpyHostToDevice);
	cudaMemcpy(d_green, green.data(), num_pixels, cudaMemcpyKind::cudaMemcpyHostToDevice);
	cudaMemcpy(d_blue, blue.data(), num_pixels, cudaMemcpyKind::cudaMemcpyHostToDevice);

	time_point<steady_clock> time_b = high_resolution_clock::now();

	make_gray<<<total_blocks, threads_per_block>>>(d_red, d_green, d_blue, num_pixels, d_gray);

	time_point<steady_clock> time_c = high_resolution_clock::now();

	cudaDeviceSynchronize();

	cudaFree(d_red);
	cudaFree(d_green);
	cudaFree(d_blue);

	cout << "Finished creating image" << endl;

	string out_filename = "result_image_cuda_um.png";
	exit_code = lodepng::encode(out_filename, d_gray, width, height, LCT_GREY);
	if (exit_code != 0) {
		cout << "Error saving file " << out_filename << " with the code " << exit_code << ": " << lodepng_error_text(exit_code) << endl;
		exit(exit_code);
	}
	else {
		cout << "Successfully saved file " << out_filename << endl;
	}

	cudaFree(d_gray);

	time_point<steady_clock> time_d = high_resolution_clock::now();

	cout << "TOTAL TIME: " << duration_cast<microseconds>(time_d - time_a).count() << " mcs." << endl;
	cout << "CALCULATION TIME: " << duration_cast<microseconds>(time_c - time_b).count() << " mcs." << endl;
}
