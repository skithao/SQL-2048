import tkinter as tk
from tkinter import messagebox
import random

class Game2048:
    def __init__(self, master):
        self.master = master
        self.master.title("2048 Game")
        self.grid = [[0, 0, 0, 0] for _ in range(4)]
        self.score = 0

        self.create_widgets()
        self.start_game()

        self.master.bind("<Key>", self.key_press)

    def create_widgets(self):
        self.score_label = tk.Label(self.master, text="Score: 0", font=("Helvetica", 24))
        self.score_label.pack()

        self.canvas = tk.Canvas(self.master, width=400, height=400, bg="lightgrey")
        self.canvas.pack()

        self.width = 100
        self.height = 100

    def start_game(self):
        self.add_new_tile()
        self.add_new_tile()
        self.render_grid()

    def add_new_tile(self):
        empty_tiles = [(i, j) for i in range(4) for j in range(4) if self.grid[i][j] == 0]
        if empty_tiles:
            i, j = random.choice(empty_tiles)
            self.grid[i][j] = 2 if random.random() < 0.9 else 4

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
                moved_row, row_moved = self.merge(row)
                if row_moved:
                    moved = True
                for j in range(4):
                    self.grid[i][j] = moved_row[j] if j < len(moved_row) else 0
        elif direction == 'Right':
            for i in range(4):
                row = [x for x in self.grid[i] if x != 0][::-1]
                moved_row, row_moved = self.merge(row)
                if row_moved:
                    moved = True
                for j in range(4):
                    self.grid[i][j] = moved_row[::-1][j] if j < len(moved_row) else 0
        elif direction == 'Up':
            for j in range(4):
                col = [self.grid[i][j] for i in range(4) if self.grid[i][j] != 0]
                moved_col, col_moved = self.merge(col)
                if col_moved:
                    moved = True
                for i in range(4):
                    self.grid[i][j] = moved_col[i] if i < len(moved_col) else 0
        elif direction == 'Down':
            for j in range(4):
                col = [self.grid[i][j] for i in range(4) if self.grid[i][j] != 0][::-1]
                moved_col, col_moved = self.merge(col)
                if col_moved:
                    moved = True
                for i in range(4):
                    self.grid[i][j] = moved_col[::-1][i] if i < len(moved_col) else 0

        if moved:
            self.score += sum(sum(row) for row in self.grid)

    def merge(self, line):
        merged = []
        moved = False
        for i in range(len(line)):
            if i < len(line) - 1 and line[i] == line[i + 1]:
                merged.append(line[i] * 2)
                moved = True
                i += 1  # Skip the next number because it's merged
            else:
                merged.append(line[i])
        return merged, moved

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
