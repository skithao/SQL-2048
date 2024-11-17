import tkinter as tk
from tkinter import messagebox
import random
import pyodbc  # 确保你已安装 pyodbc

class Game2048:
    def __init__(self, master):
        self.master = master
        self.master.title("2048 Game")
        self.grid = [[0, 0, 0, 0] for _ in range(4)]
        self.score = 0
        self.game_id = None
        self.connection = None

        # 数据库连接
        self.connect_db()
        self.create_widgets()
        self.start_game()

        self.master.bind("<Key>", self.key_press)

    def connect_db(self):
        # 这里请根据你的数据库信息进行修改
        connection_string = "Driver={SQL Server};Server=YOUR_SERVER;Database=Game2048DB;UID=YOUR_USERNAME;PWD=YOUR_PASSWORD;"
        self.connection = pyodbc.connect(connection_string)

    def create_widgets(self):
        self.score_label = tk.Label(self.master, text="Score: 0", font=("Helvetica", 24))
        self.score_label.pack()

        self.canvas = tk.Canvas(self.master, width=400, height=400, bg="lightgrey")
        self.canvas.pack()

        self.width = 100
        self.height = 100

    def start_game(self):
        self.initialize_game()
        self.add_new_tile()
        self.add_new_tile()
        self.render_grid()

    def initialize_game(self):
        # 调用存储过程初始化游戏
        cursor = self.connection.cursor()
        cursor.execute("EXEC InitGame2048 @difficultyLevel = 1")
        cursor.execute("SELECT TOP 1 GameId FROM Game2048 ORDER BY GameId DESC")
        self.game_id = cursor.fetchone()[0]
        self.load_grid_data()

    def load_grid_data(self):
        cursor = self.connection.cursor()
        cursor.execute("SELECT GridData, Score FROM Game2048 WHERE GameId = ?", self.game_id)
        result = cursor.fetchone()

        self.grid = [list(map(int, row.split(','))) for row in result[0].split(';')]
        self.score = result[1]

    def render_grid(self):
        self.canvas.delete("all")
        for i in range(4):
            for j in range(4):
                x = j * self.width
                y = i * self.height
                value = self.grid[i][j]
                color = self.get_color(value)
                self.canvas.create_rectangle(x, y, x + self.width, y + self.height, fill=color, outline="white", width=2)
                if value != 0:
                    self.canvas.create_text(x + self.width / 2, y + self.height / 2, text=str(value), font=("Helvetica", 32))

        self.score_label.config(text=f"Score: {self.score}")
        if self.is_game_over():
            messagebox.showinfo("Game Over", f"Your score: {self.score}")

    def get_color(self, value):
        colors = {
            0: "lightgrey", 2: "#eeded4", 4: "#e3c6a4",
            8: "#f1c69b", 16: "#f2b900", 32: "#f29c00",
            64: "#f86f00", 128: "#f87e00", 256: "#572FFF",
            512: "#a4d7e1", 1024: "#7CC3D9", 2048: "#51E0D1"
        }
        return colors.get(value, "#f7f0f0")

    def key_press(self, event):
        direction = event.keysym
        if direction in ['Left', 'Right', 'Up', 'Down']:
            self.move(direction)
            self.add_new_tile()
            self.render_grid()

    def move(self, direction):
        moved = False
        if direction == 'Left':
            for i in range(4):
                row = [x for x in self.grid[i] if x != 0]
                new_row, row_moved = self.merge(row)
                if row_moved:
                    moved = True
                self.grid[i] = new_row + [0] * (4 - len(new_row))
        elif direction == 'Right':
            for i in range(4):
                row = [x for x in self.grid[i] if x != 0][::-1]
                new_row, row_moved = self.merge(row)
                if row_moved:
                    moved = True
                self.grid[i] = [0] * (4 - len(new_row)) + new_row
        elif direction == 'Up':
            for j in range(4):
                col = [self.grid[i][j] for i in range(4) if self.grid[i][j] != 0]
                new_col, col_moved = self.merge(col)
                if col_moved:
                    moved = True
                for i in range(4):
                    self.grid[i][j] = new_col[i] if i < len(new_col) else 0
        elif direction == 'Down':
            for j in range(4):
                col = [self.grid[i][j] for i in range(4) if self.grid[i][j] != 0][::-1]
                new_col, col_moved = self.merge(col)
                if col_moved:
                    moved = True
                for i in range(4):
                    self.grid[i][j] = new_col[::-1][i] if i < len(new_col) else 0

        if moved:
            self.update_db()

    def merge(self, line):
        merged = []
        moved = False
        for i in range(len(line)):
            if i < len(line) - 1 and line[i] == line[i + 1]:
                merged.append(line[i] * 2)
                self.score += line[i] * 2
                moved = True
                i += 1
            else:
                merged.append(line[i])
        return merged, moved

    def update_db(self):
        grid_data = ';'.join([','.join(map(str, row)) for row in self.grid])
        cursor = self.connection.cursor()
        cursor.execute("UPDATE Game2048 SET GridData = ?, Score = ? WHERE GameId = ?", grid_data, self.score, self.game_id)
        self.connection.commit()

    def add_new_tile(self):
        empty_tiles = [(i, j) for i in range(4) for j in range(4) if self.grid[i][j] == 0]
        if empty_tiles:
            i, j = random.choice(empty_tiles)
            self.grid[i][j] = 2 if random.random() < 0.9 else 4

    def is_game_over(self):
        if any(0 in row for row in self.grid):
            return False
        for i in range(4):
            for j in range(4):
                if j < 3 and self.grid[i][j] == self.grid[i][j + 1]:
                    return False
                if i < 3 and self.grid[i][j] == self.grid[i + 1][j]:
                    return False
        return True

if __name__ == "__main__":
    root = tk.Tk()
    Game2048(root)
    root.mainloop()
