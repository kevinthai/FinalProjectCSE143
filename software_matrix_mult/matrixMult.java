import java.lang.Integer;
import java.util.Random;

public class matrixMult {
	
	public static void main(String[] args) {
		Random rand = new Random();
		int P = Integer.parseInt(args[0]);
		
		int[][] A = new int[1080][1920];
		int[][] B = new int[1920][P];
		int[][] C = new int[1080][P];
		
		//initialize A
		for(int i = 0; i < 1080; i++) {
			for(int j = 0; j < 1920; j++) {
				A[i][j] = rand.nextInt(256);
			}
		}
		
		//initialize B
		for(int i = 0; i < 1920; i++) {
			for(int j = 0; j < P; j++) {
				B[i][j] = rand.nextInt(256);
			}
		}
		
		//A*B
		for(int i = 0; i < 1080; i++) {
			for(int j = 0; j < P; j++) {
				for(int k = 0; k < 1920; k++) {
					C[i][j] += A[i][k]*B[k][j];
				}
			}			
		}
		
		int[][] result = C;
		for(int i = 0; i < 1080; i++) {
			for(int j = 0; j < P; j++) {
				System.out.println(result[i][j]);
			}
		}
		
	}
}