#include <stdbool.h>
#include "xil_printf.h"
#include "filter0.h"
#include "filter1.h"
#include "filter2.h"
#include "filter3.h"
#include "filter4.h"
#include "filter5.h"
#include "filter6.h"
#include "filter7.h"
#include "filter8.h"
#include "filter9.h"
#include "filter10.h"
#include "filter11.h"
#include "filter12.h"
#include "input.h"

#define WAVE_SIZE 1000
#define OUTPUT_SIZE 500
#define BUFFER_SIZE 279
#define NUM_BANDS 13
#define MASK_17 0x00020000
#define MASK_16_15 0x00018000

short lbuffer[BUFFER_SIZE];
short rbuffer[BUFFER_SIZE];
short* wave_in = input;
short atten_factors[NUM_BANDS] = {0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000, 0x4000};
short* filter_pointers[NUM_BANDS] = {filter0, filter1, filter2, filter3, filter4, filter5, filter6, filter7, filter8, filter9, filter10, filter11, filter12};
short output_left[OUTPUT_SIZE] = {0};
short output_right[OUTPUT_SIZE] = {0};

void initBuffer(short* buffer){
	for(int i = 0; i < BUFFER_SIZE; i++){
		buffer[i] = 0;
	}
}

int next_circ_index(int curr_index){
	if(curr_index < BUFFER_SIZE - 1){
		return curr_index + 1;
	}
	return 0;
}

int prev_circ_index(int curr_index){
	if(curr_index > 0){
		return curr_index - 1;
	}
	return BUFFER_SIZE - 1;
}

void init(){
	initBuffer(lbuffer);
	initBuffer(rbuffer);
}

short Filter(int curr_index, bool right_channel, int band){
	int i = curr_index;
	int sum = 0;
	short f, g;
	short* band_filter = filter_pointers[band];
	for(int j = 0; j < BUFFER_SIZE; j++){
		f = right_channel ? rbuffer[i] : lbuffer[i];
		g = band_filter[j];
		sum += f * g;
		i = prev_circ_index(i);
	}
	return (short)(((sum >> 14) + 1) >> 1);
}

int main(){
	init();
	int index_left = 0;
	int index_right = 0;
	int out_index_left = 0;
	int out_index_right = 0;
	bool rsample = 0;
	short filter_outputs[NUM_BANDS];
	int raw_output = 0;

	for(int i = 0; i < WAVE_SIZE; i++){
		// Collect filter outputs
		raw_output = 0;
		if(rsample){
			rbuffer[index_right] = wave_in[i];
			for(int k = 0; k < NUM_BANDS; k++){
				filter_outputs[k] = Filter(index_right, rsample, k);
			}
			index_right = next_circ_index(index_right);
		} else{
			lbuffer[index_right] = wave_in[i];
			for(int k = 0; k < NUM_BANDS; k++){
				filter_outputs[k] = Filter(index_left, rsample, k);
			}
			index_left = next_circ_index(index_left);
		}

		// Multiply the filter outputs by the attenuation factors and accumulate them
		for(int j = 0; j < NUM_BANDS; j++){
			raw_output += filter_outputs[j] * atten_factors[j];
		}

		int shifted_output = ((raw_output >> 13) + 1) >> 1;
		short rounded_output;
		bool pos_overflow = !(shifted_output & MASK_17) && (shifted_output & MASK_16_15);
		bool neg_overflow = (shifted_output & MASK_17) && !(shifted_output & MASK_16_15);

		if(pos_overflow) rounded_output = 0x7fff;
		else if(neg_overflow) rounded_output = 0x8000;
		else rounded_output = (short)shifted_output;

		if(rsample) {
			output_right[out_index_right] = rounded_output;
			out_index_right++;
		}
		else {
			output_left[out_index_left] = rounded_output;
			out_index_left++;
		}
		rsample = !rsample;
	}

	// Print the final results
	xil_printf("Left Channel:\n");
	for(int i = 0; i < OUTPUT_SIZE; i++){
		xil_printf("%d\n", output_left[i]);
	}
	xil_printf("Right Channel:\n");
	for(int j = 0; j < OUTPUT_SIZE; j++){
		xil_printf("%d\n", output_right[j]);
	}
}
