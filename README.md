# The Last Platform  

A 2D platformer game built in MIPS Assembly for the CSCB58 course.  

---

## **Game Overview**  
**The Last Platform** is a 2D platformer where the player navigates platforms, avoids enemies, and collects a special pickup to win. The player can shoot enemies to disable them temporarily, but colliding with enemies costs lives. The game ends when the player either collects the pickup (win) or loses all three lives (game over).  

---

## **Features**  
✅ **Player Movement**  
- Move left (`A`), right (`D`), jump up (`W`), and fall down (`S`).  
- Gravity pulls the player down unless standing on a platform.  

✅ **Enemies**  
- Two enemies move horizontally across the screen.  
- Shoot them with `SPACE` to temporarily disable them.  
- Enemies respawn after a short delay.  

✅ **Platforms**  
- Four static platforms where the player can land.  

✅ **Pickup Object (Win Condition)**  
- A purple box that the player must collect to win.  

✅ **Lives System**  
- **3 lives** (displayed as red hearts at the top).  
- Colliding with an enemy reduces lives by 1.  
- Losing all lives results in a **game over**.  

✅ **Win/Lose Screens**  
- **Win Screen:** Displays "YOU WIN!" and remaining lives.  
- **Lose Screen:** Displays "YOU LOSE" and a "0" for lives.  

✅ **Restart & Quit**  
- Press `R` to restart the game.  
- Press `Q` to exit.  

---

## **Controls**  
| Key       | Action               |  
|-----------|----------------------|  
| `W`       | Move Up              |  
| `A`       | Move Left            |  
| `S`       | Move Down            |  
| `D`       | Move Right           |  
| `SPACE`   | Shoot Bullet         |  
| `R`       | Restart Game         |  
| `Q`       | Quit Game            |  

---

## **Technical Details**  
#### **MARS Bitmap Display Configuration**  
- **Unit Width:** 4 pixels  
- **Unit Height:** 4 pixels  
- **Display Width:** 256 pixels  
- **Display Height:** 256 pixels  
- **Base Address:** `0x10008000`

#### **MARS Keyboard and Display MMIO Simulator**

#### **Implemented Milestones**  
- **Milestone 1:** Basic player movement and platforms.  
- **Milestone 2:** Enemies with collision detection.  
- **Milestone 3:** Shooting mechanics and win/lose conditions.  
- **Milestone 4:** Additional features (score display, pickup object).  

#### **Additional Features**  
- Moving enemies.  
- Shooting mechanics.  
- Win condition (collect pickup).  
- Lose condition (lose all lives).  

---

## **Demo Video**  
[Watch the gameplay demo here!](https://youtu.be/22EZa2zj2D0)  

---

## **Notes**  
⚠ **Exit Delay:** The game takes ~5 seconds to exit after the win/lose screen.  
⚠ **Pickup Collision:** The collision may not always be visibly clear but still triggers the win condition.  

---
**Enjoy The Last Platform!** 🎮  
