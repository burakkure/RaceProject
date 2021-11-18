#include <cuda_runtime.h>
#include <iostream>
#include <time.h>
#include <string>
#include <vector>
#include <algorithm>
#include <unistd.h>

using namespace std;

class Runner {       
  public:             
    double speed;
    double currentPosition;
    string name;
    bool isFinished;
    double finishTime;

    __host__ Runner();
    __host__ ~Runner();
    __host__ Runner(string nameOfRunner);
};

__host__ Runner::Runner()
{
        
}
__host__ Runner::~Runner()
{
        
}
__host__ Runner::Runner(string nameOfRunner)
{
    speed = 4.0 * ( (double)rand() / (double)RAND_MAX ) + 1.0;
    currentPosition = 0.0;
    name = "Kosucu " + nameOfRunner;
    isFinished = false;
    finishTime = 0;
}

class Race {       
  public:             
    int runwayLength;        
    int numberOfRunners;
    int timePassed;
    bool isFirstFinished;
    bool isRaceFinished;
    Runner* runners;

    __host__ Race(int lenght, int runnerNumber);
    __host__ Race();
    __host__ ~Race();
    __device__ void calculateNewPosition(int idx);
    __host__ void check();
    __host__ void printAllRunners(bool position);
    __host__ void sortRunners();
};

__host__ Race::Race(int lenght, int runnerNumber){
    runwayLength = lenght;
    numberOfRunners = runnerNumber;
        
    cudaMallocManaged(&runners, runnerNumber*sizeof(Runner));
        
    for (int i = 0; i < numberOfRunners; i++) {
        runners[i] = Runner(to_string(i+1));
    }
        
    isFirstFinished = false;
    isRaceFinished = false;
    timePassed = 0;
         
}

__host__ Race::Race()
{
}

__host__ Race::~Race()
{
}
    
__device__ void Race::calculateNewPosition(int idx)
{
	if(!runners[idx].isFinished){
        runners[idx].currentPosition += runners[idx].speed;
    }
}
    
__host__ void Race::check()
{
    bool isFirstFinishedTemp = isFirstFinished;
    isRaceFinished = true;
    for (int i = 0; i < numberOfRunners; i++) {
        if(runners[i].currentPosition > runwayLength && !runners[i].isFinished){
            runners[i].isFinished = true;
            runners[i].finishTime = timePassed - (double)(runners[i].currentPosition-runwayLength)/runners[i].speed;
            runners[i].currentPosition = runwayLength;
                
            if(!isFirstFinished){
                isFirstFinished = true;
            }
        }
        if(!runners[i].isFinished)
            isRaceFinished = false;
    }
    if(!isFirstFinishedTemp && isFirstFinished){
        cout<<"***Bitis cizgisine ilk kosucu ulasti!***\n";
        cout<<"-Kosucularin anlik konumlari:\n";
        printAllRunners(true);
    }
        
}
    
__host__ void Race::printAllRunners(bool position)
{
    for(int i=0;i<numberOfRunners; i++){
        if(position)
            cout<< runners[i].name <<"; Konumu: "<<runners[i].currentPosition<<"m \n";
        else
            cout<<i+1<<". Yarisci: " <<runners[i].name <<"; Hizi: " <<runners[i].speed<<" m/s, Bitirme suresi: "<<runners[i].finishTime<<"s\n";
    }
}
    
__host__ void Race::sortRunners()
{
    for(int i=0;i<numberOfRunners; i++){
        for(int j=0;j<numberOfRunners-1; j++){
            if(runners[j].finishTime > runners[j+1].finishTime){
                Runner temp = runners[j];
                runners[j] = runners[j+1];
                runners[j+1] = temp;
            }
                
        }
    }
}


__global__ void raceKernel(Race race)
{
	const int idx = blockIdx.x*blockDim.x + threadIdx.x;
	if(idx < race.numberOfRunners)
	{
		race.calculateNewPosition(idx);
	}

}


int main()
{
    srand(time(NULL)); 
    int runwayLength = 100;
    int runnerNumber = 100;
    Race race = Race(runwayLength,runnerNumber);
    int currentTime = 0;
    cout<<"****Yaris basladi!****\n\n";
    while(!race.isRaceFinished)
    {
	cout<<"Gecen sure: "<<currentTime++<<"s\n";
    	raceKernel<<<1,runnerNumber>>>(race);
    	cudaDeviceSynchronize();
        
        race.timePassed = race.timePassed + 1;
        race.check();

        usleep(1000000);
    }
    
    cout<<"\n****Yaris bitti!****\n";
    cout<<"-Siralama:\n";
    
    race.sortRunners();
    race.printAllRunners(false);
    
    cudaFree(race.runners);
    
    return 0;
}
