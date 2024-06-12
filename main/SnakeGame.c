#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "driver/gpio.h"
#include "driver/i2c.h"
#include "esp_system.h"
#include "esp_timer.h"
#include "esp_log.h"
#include "sdkconfig.h"

#include "Adafruit_GFX.h"
#include "Adafruit_SSD1306.h"

#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64

#define RIGHT 0
#define UP    1
#define LEFT  2
#define DOWN  3

#define BUTTON_UP_PIN GPIO_NUM_4
#define BUTTON_DOWN_PIN GPIO_NUM_5
#define BUTTON_LEFT_PIN GPIO_NUM_15
#define BUTTON_RIGHT_PIN GPIO_NUM_18
#define BUTTON_RESET_PIN GPIO_NUM_2
#define BUZZER_PIN GPIO_NUM_19

Adafruit_SSD1306 display(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, -1);

static const char *TAG = "SnakeGame";

int score = 0;
int highScore = 0;
int level = 1;
int gamespeed = 100;
bool isGameOver = false;
int dir = RIGHT;

struct FOOD {
    int x;
    int y;
    int yes;
};

struct SNAKE {
    int x[200];
    int y[200];
    int node;
    int dir;
};

FOOD food;
SNAKE snake;

void element(int x, int y) {
    display.fillRect(x, y, 8, 8, SSD1306_WHITE);
}

void UI() {
    display.drawRect(0, 1, 128, 64, SSD1306_WHITE);
    display.drawRect(0, 0, 128, 64, SSD1306_WHITE);
}

void IRAM_ATTR buttonUpISR(void* arg) {
    dir = UP;
}

void IRAM_ATTR buttonDownISR(void* arg) {
    dir = DOWN;
}

void IRAM_ATTR buttonLeftISR(void* arg) {
    dir = LEFT;
}

void IRAM_ATTR buttonRightISR(void* arg) {
    dir = RIGHT;
}

void generateFood() {
    do {
        food.x = (esp_random() % 16) * 8;
        food.y = (esp_random() % 8) * 8;
    } while (isFoodOnSnake());
}

bool isFoodOnSnake() {
    for (int i = 0; i < snake.node; i++) {
        if (food.x == snake.x[i] && food.y == snake.y[i]) {
            return true;
        }
    }
    return false;
}

void snakeGame() {
    switch (snake.dir) {
        case RIGHT:
            snake.x[0] += 8;
            if (snake.x[0] > 120)
                snake.x[0] = 0;
            break;
        case UP:
            snake.y[0] -= 8;
            if (snake.y[0] < 0)
                snake.y[0] = 56;
            break;
        case LEFT:
            snake.x[0] -= 8;
            if (snake.x[0] < 0)
                snake.x[0] = 120;
            break;
        case DOWN:
            snake.y[0] += 8;
            if (snake.y[0] > 56)
                snake.y[0] = 0;
            break;
    }

    // Checks for snake's collision with the food
    if ((snake.x[0] == food.x) && (snake.y[0] == food.y)) {
        snake.x[0] = food.x;
        snake.y[0] = food.y;
        snake.node++;
        food.yes = 1;
        score += 2;
        level = score / 10 + 1;
        gpio_set_level(BUZZER_PIN, 1);
        vTaskDelay(100 / portTICK_PERIOD_MS);
        gpio_set_level(BUZZER_PIN, 0);
        generateFood();
    }

    // Checks for collision with the body
    for (int i = 1; i < snake.node; i++) {
        if (snake.x[0] == snake.x[i] && snake.y[0] == snake.y[i]) {
            isGameOver = true;
        }
    }

    // update snake body
    for (int i = snake.node - 1; i > 0; i--) {
        snake.x[i] = snake.x[i - 1];
        snake.y[i] = snake.y[i - 1];
    }
}

void key() {
    if (dir == DOWN && snake.dir != UP) {
        snake.dir = DOWN;
    }
    if (dir == RIGHT && snake.dir != LEFT) {
        snake.dir = RIGHT;
    }
    if (dir == LEFT && snake.dir != RIGHT) {
        snake.dir = LEFT;
    }
    if (dir == UP && snake.dir != DOWN) {
        snake.dir = UP;
    }
}

void displaySnake() {
    for (int i = 0; i < snake.node; i++) {
        element(snake.x[i], snake.y[i]);
    }
}

void resetGame() {
    if (score > highScore) {
        highScore = score;
    }
    score = 0;
    level = 1;
    isGameOver = false;
    dir = RIGHT;

    snake.x[0] = 64;
    snake.y[0] = 32;
    snake.x[1] = 56;
    snake.y[1] = 32;
    snake.dir = RIGHT;
    snake.node = 2;

    generateFood();
}

void gameOver() {
    gpio_set_level(BUZZER_PIN, 1);
    vTaskDelay(500 / portTICK_PERIOD_MS);
    gpio_set_level(BUZZER_PIN, 0);

    display.clearDisplay();
    display.setTextSize(2);
    display.setTextColor(SSD1306_WHITE);
    display.setCursor(20, 10);
    display.println("Game Over");
    display.setCursor(20, 30);
    display.print("Score: ");
    display.println(score);
    display.setCursor(20, 50);
    display.print("High Score: ");
    display.println(highScore);
    display.display();
}

void gameLoop(void* pvParameters) {
    while (1) {
        if (!isGameOver) {
            display.clearDisplay();
            displaySnake();
            element(food.x, food.y);

            display.display();

            key();
            snakeGame();
            vTaskDelay(gamespeed / portTICK_PERIOD_MS);
        } else {
            gameOver();
            while (isGameOver) {
                if (gpio_get_level(BUTTON_RESET_PIN) == 0) {
                    resetGame();
                }
                vTaskDelay(100 / portTICK_PERIOD_MS);
            }
        }
    }
}

extern "C" void app_main() {
    gpio_set_direction(BUTTON_UP_PIN, GPIO_MODE_INPUT);
    gpio_set_direction(BUTTON_DOWN_PIN, GPIO_MODE_INPUT);
    gpio_set_direction(BUTTON_LEFT_PIN, GPIO_MODE_INPUT);
    gpio_set_direction(BUTTON_RIGHT_PIN, GPIO_MODE_INPUT);
    gpio_set_direction(BUTTON_RESET_PIN, GPIO_MODE_INPUT);
    gpio_set_direction(BUZZER_PIN, GPIO_MODE_OUTPUT);

    gpio_set_pull_mode(BUTTON_UP_PIN, GPIO_PULLUP_ONLY);
    gpio_set_pull_mode(BUTTON_DOWN_PIN, GPIO_PULLUP_ONLY);
    gpio_set_pull_mode(BUTTON_LEFT_PIN, GPIO_PULLUP_ONLY);
    gpio_set_pull_mode(BUTTON_RIGHT_PIN, GPIO_PULLUP_ONLY);
    gpio_set_pull_mode(BUTTON_RESET_PIN, GPIO_PULLUP_ONLY);

    gpio_install_isr_service(0);
    gpio_isr_handler_add(BUTTON_UP_PIN, buttonUpISR, NULL);
    gpio_isr_handler_add(BUTTON_DOWN_PIN, buttonDownISR, NULL);
    gpio_isr_handler_add(BUTTON_LEFT_PIN, buttonLeftISR, NULL);
    gpio_isr_handler_add(BUTTON_RIGHT_PIN, buttonRightISR, NULL);

    Wire.begin();
    if (!display.begin(SSD1306_SWITCHCAPVCC, 0x3C)) {
        ESP_LOGE(TAG, "SSD1306 allocation failed");
        while (1);
    }
    display.display();
    vTaskDelay(2000 / portTICK_PERIOD_MS);
    display.clearDisplay();

    food = {40, 48, 1};

    snake.x[0] = 64;
    snake.y[0] = 32;
    snake.x[1] = 56;
    snake.y[1] = 32;
    snake.dir = RIGHT;
    snake.node = 2;

    xTaskCreate(&gameLoop, "gameLoop", 2048, NULL, 5, NULL);
}
