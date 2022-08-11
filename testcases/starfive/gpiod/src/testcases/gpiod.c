/*
* Copyright statement:
* Copyright disclaimer:
*
*
*
* Date: 11/8/2022
* Contact: Teh Yu Sheng(yusehng.teh@starfivetech.com),
* 	   Tan Chun Hau(chunhau.tan@starfivetech.com)

*******************************************************************************
* @objective: Test the read write ability of GPIO driver
* @desc: Read the overwrite value of input pin no & output pin no from get_pin_num.sh
*	 Request the first pin to be output pin and second pin to be input pin.
*	 Send 10 pulse from output pin to received pin.
*	 Success if 10 signals from output pin is received by the input pin.
*
* @returns: 0 for success, < 0 if failed;
* 	    details return number can be found at testcases/ddt/utils/user/st_defines.h
*/

/******************************************************************************/

#include <gpiod.h>
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/select.h>
#include <unistd.h>

#include <st_defines.h>
#include <st_log.h>

#ifndef CONSUMER
#define CONSUMER    "LTP-DDT"
#endif

#define READ 0
#define WRITE 1

char *testcaseid = "gpiod_tests";
int pipeFromReadThreadToMain[2];
int pipeFromWriteThreadToReadThread[2];

void *generate_pwm_random_interval( void *ptr );
void *detect_pwm( void *ptr );

int main(int argc, char const *argv[])
{
	int i, err, resultFromThread, chk;
	char *chipname = "gpiochip0";
	pthread_t threadWrite, threadRead;
	static unsigned int lineNumWrite;	//line number of writting pin
	static unsigned int lineNumRead;	//line number of reading pin
	struct gpiod_chip *chip;
	struct gpiod_line *lineWrite;
	struct gpiod_line *lineRead;

	//checking if correct amount of arguments is passed
	for (int i = 1; i < 4; i++){
		if (i < 3 && argv[i] == NULL){
			TEST_PRINT_ERR("Error! Less than 2 arguments is passed. Please pass 2 arguments to the program\n");
			err = FAILURE;
			goto end;
		}
		else if(i == 3 && argv[i] != NULL){
			TEST_PRINT_ERR("Error! More than 2 arguments is passd. Please pass 2 arguments to the program\n");
			err = FAILURE;
			goto end;
		}
	}

	lineNumWrite = atoi(argv[1]);
	lineNumRead = atoi(argv[2]);

	chip = gpiod_chip_open_by_name(chipname);
	if (!chip) {
		TEST_PRINT_ERR("Open chip failed\n");
		err = FAILURE;
		goto end;
	}

	lineWrite = gpiod_chip_get_line(chip, lineNumWrite);
	if (!lineWrite) {
		TEST_PRINT_ERR("Error! Failed to get line 1\n");
		err = FAILURE;
		goto close_chip;
	}

	lineRead = gpiod_chip_get_line(chip, lineNumRead);
	if (!lineRead) {
		TEST_PRINT_ERR("Error! Failed to get line 2\n");
		err = FAILURE;
		goto release_line_write;
	}

	chk = gpiod_line_request_output(lineWrite, CONSUMER, 0);
	if (chk < SUCCESS){
		TEST_PRINT_ERR("Error! Failed to request output at line 1\n");
		err = FAILURE;
		goto release_line_read;
	}

	chk = gpiod_line_request_input(lineRead, CONSUMER);
	if (chk < SUCCESS){
		TEST_PRINT_ERR("Error! Failed to request output at line 1\n");
		err = FAILURE;
		goto release_line_read;
	}

	chk = gpiod_line_request_both_edges_events(lineRead, CONSUMER);
	if (chk < SUCCESS){
		TEST_PRINT_ERR("Error! Failed to request input at line 2\n");
		err = FAILURE;
		goto release_line_read;
	}

	//create 2 thread, one send output, one received input
	//join both threads
	chk = pipe(pipeFromWriteThreadToReadThread);
	if (chk < SUCCESS){
		TEST_PRINT_ERR("Error! Failed to initiate pipe from thread 1 to thread 2");
		err = FAILURE;
		goto release_line_read;
	}

	chk = pthread_create( &threadWrite, NULL, generate_pwm_random_interval, (void*) lineWrite);
	if (chk < SUCCESS){
		TEST_PRINT_ERR("Error! Failed to generate pwm at pin 0\n");
		err = FAILURE;
		goto closePipeThreadToMain;
	}

	chk = pthread_create( &threadRead, NULL, detect_pwm, (void*) lineRead);
	if (chk < SUCCESS){
		TEST_PRINT_ERR("Error! Failed to generate pwm at pin 0\n");
		err = FAILURE;
		pthread_join(threadWrite, NULL);
		goto closePipeThreadToMain;
	}

	chk = pipe(pipeFromReadThreadToMain);
	if (chk < SUCCESS){
		TEST_PRINT_ERR("Failed to initiate pipe\n");
		err = FAILURE;
		goto closePipeThreadToMain;
	}

	chk = read(pipeFromReadThreadToMain[READ], &resultFromThread, sizeof(int));
	if (chk < SUCCESS){
		TEST_PRINT_ERR("Failed to read from thread \n");
		err = FAILURE;
	}

	closePipeThreadToMain:
	close(pipeFromReadThreadToMain[READ]);
	close(pipeFromReadThreadToMain[WRITE]);
	pthread_join(threadWrite, NULL);
	pthread_join(threadRead, NULL);

	closePipeThread1ToThread2:
	close(pipeFromWriteThreadToReadThread[READ]);
	close(pipeFromWriteThreadToReadThread[WRITE]);

	release_line_read:
	gpiod_line_release(lineRead);

	release_line_write:
	gpiod_line_release(lineWrite);

	close_chip:
	gpiod_chip_close(chip);
	end:
	if (err < resultFromThread)
		resultFromThread = err;

	TEST_PRINT_TST_RESULT(resultFromThread, testcaseid);
	TEST_PRINT_TST_END(testcaseid);
	return resultFromThread;
}

void *generate_pwm_random_interval( void *ptr )
{
	int i, err = SUCCESS, val = 0, timing;
	struct gpiod_line *line = ptr;
	int pwmNum = 0, chk;
	for (i = 0; i < 10; i++){
		val = !val;

		chk = gpiod_line_set_value(line, val);
		if (chk < SUCCESS){
			TEST_PRINT_ERR("Error! Unable to write value at output pin %u\n", line);
			err = FAILURE;
			break;
		}else{
			printf("Output pin %u is set as %d \n", &line, val);
		}

		timing = (rand()%10 + 1)*100000;	//generate timing of 0.1s, 0.2s, 0.3s...1s
		pwmNum++;
		if (write(pipeFromWriteThreadToReadThread[WRITE], &pwmNum, sizeof(int)) < SUCCESS){
			TEST_PRINT_ERR("Failed to send pwm count to thread 2\n");
			err = FAILURE;
			break;
		}
		usleep(timing);
	}
	return err;
}

void *detect_pwm( void *ptr )
{
	int timing, counter = 0;
	struct gpiod_line *line = ptr;
	struct timespec ts = { 3, 0 };
	struct gpiod_line_event event;
	int err, pwmFromOutput, result, chk;

	while (true) {
		chk = gpiod_line_event_wait(line, &ts);
		if (chk < SUCCESS) {
			TEST_PRINT_ERR("Error! Wait event notification failed\n");
		break;
		} else if (chk == 0) {
			TEST_PRINT_ERR("FAILED! Wait event notification on line #%u timeout\n", line);
		err = TIMEOUT;
		break;
		}

		chk = gpiod_line_event_read(line, &event);
		if (chk < SUCCESS){
			TEST_PRINT_ERR("Read last event notification failed\n");
			err = FAILURE;
		break;
		}

		chk = read(pipeFromWriteThreadToReadThread[READ], &pwmFromOutput, sizeof(int));
		if (chk < SUCCESS){
			TEST_PRINT_ERR("Error! Receive from input thread pwm count failed\n");
			err = FAILURE;
			break;
		}
		switch (event.event_type)
		{
			case GPIOD_LINE_EVENT_RISING_EDGE:{
				printf("Rising edge detected \n");
				counter++;
				break;
				}

			case GPIOD_LINE_EVENT_FALLING_EDGE:{
				printf("Falling edge detected\n");
				counter++;
				break;
			}

			default:{}
		}

		if (pwmFromOutput == counter && pwmFromOutput == 10){
			TEST_PRINT_TRC("10 signal detected successfully\n");
			result = SUCCESS;
			break;
		}
		else if (pwmFromOutput != counter){
			TEST_PRINT_ERR("FAILED! %d signal detected while %d signal sent\n",
					counter, pwmFromOutput);
			result = FAILURE;
			break;
		}
	}

	if (err < SUCCESS)
		result = err;

	err = write(pipeFromReadThreadToMain[WRITE], &result, sizeof(int));
	if (err < SUCCESS){
		TEST_PRINT_ERR("Error! Failed to write into main thread\n");
	}
	return err;
}
