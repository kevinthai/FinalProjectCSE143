#!/usr/bin/python
import sys
import random
random.seed()

if(len(sys.argv) != 2):
	exit("Usage: python generateMatrices.py <int> (note: int must be greater than or equal to 1)")

maxValue = 255
M = 1080
N = 1920
P = int(sys.argv[1])

#creates rantom matrix with specified dimensions
def initializeRandomMatrix(rows, cols):
	matrix = []
	for i in range(0, rows):
		for j in range(0, cols):
			matrix.append(random.randint(0, maxValue))
	return matrix

# initialize matrices
A = initializeRandomMatrix(M, N)
B = initializeRandomMatrix(N, P)

	
# Open a file
file = open("matrix.txt", "w")
for i, matrix in enumerate([A, B]):
	if i != 0:
		file.write("\n")
	for element in matrix:
		file.write(str(element) + "\n")
	