import tkinter as tk
from PIL import ImageGrab
import time
import os

save_path = os.path.join(os.getenv("TEMP"), "snip_result.png")

class SnippingTool:
    def __init__(self):
        print("Initializing SnippingTool...")
        self.root = tk.Tk()
        self.root.attributes("-fullscreen", True)
        self.root.attributes("-alpha", 0.3)
        self.root.config(bg='black')

        self.start_x = None
        self.start_y = None
        self.rect = None

        self.canvas = tk.Canvas(self.root, cursor="cross", bg="black", highlightthickness=0)
        self.canvas.pack(fill=tk.BOTH, expand=True)

        self.canvas.bind("<ButtonPress-1>", self.on_start)
        self.canvas.bind("<B1-Motion>", self.on_drag)
        self.canvas.bind("<ButtonRelease-1>", self.on_snip)

        print("Starting mainloop")
        self.root.mainloop()

    def on_start(self, event):
        print(f"Start: {event.x}, {event.y}")
        self.start_x = event.x
        self.start_y = event.y
        self.rect = self.canvas.create_rectangle(self.start_x, self.start_y, self.start_x, self.start_y, outline='red', width=2)

    def on_drag(self, event):
        cur_x = event.x
        cur_y = event.y
        self.canvas.coords(self.rect, self.start_x, self.start_y, cur_x, cur_y)

    def on_snip(self, event):
        x1 = min(self.start_x, event.x)
        y1 = min(self.start_y, event.y)
        x2 = max(self.start_x, event.x)
        y2 = max(self.start_y, event.y)

        print(f"Snip coordinates: {x1}, {y1}, {x2}, {y2}")

        self.root.withdraw()
        time.sleep(0.2)  # Wait for window to hide

        # Grab the full screen bbox
        img = ImageGrab.grab(bbox=(x1, y1, x2, y2))
        img.save(save_path)
        print(f"Image saved to {save_path}")

        self.root.quit()

if __name__ == "__main__":
    SnippingTool()
