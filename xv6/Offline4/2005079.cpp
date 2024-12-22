#include <iostream>
#include <pthread.h>
#include <semaphore.h>
#include <queue>
#include <chrono>
#include <random>
#include <thread>
#include <unistd.h>
#include <fstream>

#define STEP_COUNT 3
#define GALLARY_MAX_CAPACITY 5
#define GLASS_CORRIDOR_MAX_CAPACITY 3
#define STAIR_DELAY 2

using namespace std;

// sem_t step[STEP_COUNT];
sem_t gallery1;
sem_t glassCorridor;
sem_t gallery2;
// sem_t premiumAccess;
// sem_t standardAccess;

mutex print_mutex;

pthread_mutex_t step[STEP_COUNT];
pthread_mutex_t standardLock;
pthread_mutex_t premiumLock;
pthread_mutex_t premiumAccess;
pthread_mutex_t standardAccess;

int N, M;
int w, x, y, z;
int standardCount = 0;
int premiumCount = 0;

chrono::steady_clock::time_point start_time;

void init_semaphore()
{
    for (int i = 0; i < STEP_COUNT; i++)
    {
        // sem_init(&step[i], 0, 1);
        pthread_mutex_init(&step[i], NULL);
    }
    sem_init(&gallery1, 0, GALLARY_MAX_CAPACITY);
    sem_init(&glassCorridor, 0, GLASS_CORRIDOR_MAX_CAPACITY);
    sem_init(&gallery2, 0, N + M);
    pthread_mutex_init(&standardLock, NULL);
    pthread_mutex_init(&premiumLock, NULL);
    pthread_mutex_init(&premiumAccess, NULL);
    pthread_mutex_init(&standardAccess, NULL);
    // sem_init(&premiumAccess, 0, 1);
    // sem_init(&standardAccess, 0, 1);
}

void destroy_semaphore()
{
    for (int i = 0; i < STEP_COUNT; i++)
    {
        // sem_destroy(&step[i]);
        pthread_mutex_destroy(&step[i]);
    }
    sem_destroy(&gallery1);
    sem_destroy(&glassCorridor);
    sem_destroy(&gallery2);
    pthread_mutex_destroy(&standardLock);
    pthread_mutex_destroy(&premiumLock);
    pthread_mutex_destroy(&premiumAccess);
    pthread_mutex_destroy(&standardAccess);
    // sem_destroy(&premiumAccess);
    // sem_destroy(&standardAccess);
}

int get_random_number(double lambda)
{
    random_device rd;
    mt19937 generator(rd());
    poisson_distribution<int> poissonDist(lambda);
    return poissonDist(generator);
}

void print_timestamped_message(const string &message, int visitor_id, chrono::steady_clock::time_point start_time)
{
    auto now = chrono::steady_clock::now();
    auto elapsed = chrono::duration_cast<chrono::seconds>(now - start_time).count();
    lock_guard<mutex> lock(print_mutex);
    cout << "Visitor " << visitor_id << " " << message << " at timestamp " << elapsed << endl;
}

void *premium(void *arg)
{
    int id = *((int *)arg);
    delete (int *)arg;

    pthread_mutex_lock(&premiumLock);
    premiumCount++;
    if (premiumCount == 1)
    {
        // sem_wait(&standardAccess);
        pthread_mutex_lock(&standardAccess);
    }
    pthread_mutex_unlock(&premiumLock);

    // sem_wait(&premiumAccess);
    pthread_mutex_lock(&premiumAccess);
    print_timestamped_message("is inside the photo booth", id, start_time);
    sleep(z);
    // sem_post(&premiumAccess);
    pthread_mutex_unlock(&premiumAccess);

    pthread_mutex_lock(&premiumLock);
    premiumCount--;
    if (premiumCount == 0)
    {
        // sem_post(&standardAccess);
        pthread_mutex_unlock(&standardAccess);
    }
    pthread_mutex_unlock(&premiumLock);
}

void *standard(void *arg)
{
    int id = *((int *)arg);
    delete (int *)arg;

    // sem_wait(&standardAccess);
    pthread_mutex_lock(&standardAccess);
    pthread_mutex_lock(&standardLock);
    standardCount++;
    if (standardCount == 1)
    {
        // sem_wait(&premiumAccess);
        pthread_mutex_lock(&premiumAccess);
    }
    pthread_mutex_unlock(&standardLock);
    // sem_post(&standardAccess);
    pthread_mutex_unlock(&standardAccess);

    print_timestamped_message("is inside the photo booth", id, start_time);
    sleep(z);

    pthread_mutex_lock(&standardLock);
    standardCount--;
    if (standardCount == 0)
    {
        // sem_post(&premiumAccess);
        pthread_mutex_unlock(&premiumAccess);
    }
    pthread_mutex_unlock(&standardLock);
}

void *visitMuseum(void *arg)
{
    int id = *((int *)arg);
    delete (int *)arg;

    pthread_t photoBooth;

    int delay = get_random_number(5.0);
    this_thread::sleep_for(chrono::seconds(delay));

    int glass_door_delay = get_random_number(3.0);

    print_timestamped_message("has arrived at A", id, start_time);
    sleep(w);

    print_timestamped_message("has arrived at B", id, start_time);

    // sem_wait(&step[0]);
    pthread_mutex_lock(&step[0]);
    print_timestamped_message("is at step " + to_string(0), id, start_time);
    sleep(STAIR_DELAY);
    for (int i = 0; i < STEP_COUNT - 1; i++)
    {
        // sem_wait(&step[i + 1]);
        pthread_mutex_lock(&step[i + 1]);
        print_timestamped_message("is at step " + to_string(i + 2), id, start_time);
        // sem_post(&step[i]);
        pthread_mutex_unlock(&step[i]);
        sleep(STAIR_DELAY);
    }

    sem_wait(&gallery1);
    print_timestamped_message("is at C (entered Gallery 1)", id, start_time);
    // sem_post(&step[STEP_COUNT - 1]);
    pthread_mutex_unlock(&step[STEP_COUNT - 1]);
    sleep(x);

    sem_wait(&glassCorridor);
    print_timestamped_message("is at D (entered Glass Corridor)", id, start_time);
    sem_post(&gallery1);
    sleep(glass_door_delay);
    sem_post(&glassCorridor);

    sem_wait(&gallery2);
    print_timestamped_message("is at E (entered Gallery 2)", id, start_time);
    sleep(y);
    sem_post(&gallery2);

    if (id >= 1001 && id <= 1100)
    {
        int *temp_id = new int(id);
        print_timestamped_message("is about to enter the photo booth", id, start_time);
        // pthread_create(&photoBooth, nullptr, standard, temp_id);
        standard(temp_id);
    }
    else
    {
        int *temp_id = new int(id);
        print_timestamped_message("is about to enter the photo booth", id, start_time);
        // pthread_create(&photoBooth, nullptr, premium, temp_id);
        premium(temp_id);
    }
    pthread_join(photoBooth, nullptr);

    print_timestamped_message("has completed the museum visit", id, start_time);
}

int main()
{
    freopen("input.txt", "r", stdin);
    freopen("output.txt", "w", stdout);
    // cout << "Enter the number of standard visitors: ";
    cin >> N;
    // cout << "Enter the number of premium visitors: ";
    cin >> M;
    // cout << "Time spent in hallway: ";
    cin >> w;
    // cout << "Time spent in gallery 1: ";
    cin >> x;
    // cout << "Time spent in gallery 2: ";
    cin >> y;
    // cout << "Time spent in photo booth: ";
    cin >> z;
    init_semaphore();
    int totalVisitors = N + M;
    pthread_t visitors[totalVisitors];
    start_time = chrono::steady_clock::now();
    for (int i = 0; i < N; i++)
    {
        int *id = new int(1001 + i);
        pthread_create(&visitors[i], nullptr, visitMuseum, id);
    }
    for (int i = 0; i < M; i++)
    {
        int *id = new int(2001 + i);
        pthread_create(&visitors[N + i], nullptr, visitMuseum, id);
    }
    for (int i = 0; i < totalVisitors; i++)
    {
        pthread_join(visitors[i], nullptr);
    }
    destroy_semaphore();
    return 0;
}