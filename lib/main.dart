import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const SnakeGameApp());
}

class SnakeGameApp extends StatelessWidget {
  const SnakeGameApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: Brightness.dark),
      home: const SnakeGamePage(),
    );
  }
}

class SnakeGamePage extends StatefulWidget {
  const SnakeGamePage({Key? key}) : super(key: key);

  @override
  State<SnakeGamePage> createState() => _SnakeGamePageState();
}

enum Direction { up, down, left, right }

class _SnakeGamePageState extends State<SnakeGamePage> {
  // --- Configuration ---
  final int squaresPerRow = 20;
  int squaresPerCol = 0;

  // --- State Variables ---
  List<int> snakePos = [];
  int foodPos = 0;
  Direction currentDirection = Direction.right;
  int score = 0;
  int highScore = 0;
  bool isPlaying = false;
  Timer? gameLoop;

  @override
  void dispose() {
    gameLoop?.cancel();
    super.dispose();
  }

  // --- Game Logic ---

  void startGame() {
    setState(() {
      isPlaying = true;
      score = 0;
      currentDirection = Direction.right;
      // We will initialize snake positions after the grid is built
    });

    // Slight delay to allow LayoutBuilder to calculate grid size first
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!mounted) return;
      int center = (squaresPerRow * squaresPerCol) ~/ 2;
      setState(() {
        snakePos = [center, center + 1, center + 2];
        generateNewFood();
      });

      gameLoop = Timer.periodic(const Duration(milliseconds: 150), (timer) {
        updateGame();
      });
    });
  }

  void updateGame() {
    setState(() {
      if (snakePos.isEmpty) return; // Guard clause

      int newHead = getNextHead();

      if (isWall(newHead) || snakePos.contains(newHead)) {
        gameOver();
        return;
      }

      snakePos.add(newHead);

      if (newHead == foodPos) {
        score++;
        generateNewFood();
      } else {
        snakePos.removeAt(0);
      }
    });
  }

  int getNextHead() {
    int currentHead = snakePos.last;
    switch (currentDirection) {
      case Direction.left:
        return currentHead - 1;
      case Direction.right:
        return currentHead + 1;
      case Direction.up:
        return currentHead - squaresPerRow;
      case Direction.down:
        return currentHead + squaresPerRow;
    }
  }

  bool isWall(int index) {
    int row = index ~/ squaresPerRow;
    int col = index % squaresPerRow;
    return row == 0 ||
        row == squaresPerCol - 1 ||
        col == 0 ||
        col == squaresPerRow - 1;
  }

  void generateNewFood() {
    while (true) {
      int randomPos = Random().nextInt(squaresPerRow * squaresPerCol);
      if (!snakePos.contains(randomPos) && !isWall(randomPos)) {
        foodPos = randomPos;
        break;
      }
    }
  }

  void gameOver() {
    gameLoop?.cancel();
    if (score > highScore) highScore = score;
    setState(() {
      isPlaying = false;
    });
  }

  // --- UI Building ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      // Logic: If playing, show Game Structure. If not, show Full Screen Menu.
      body: isPlaying ? buildGameStructure() : buildMainMenu(),
    );
  }

  Widget buildMainMenu() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF1B5E20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("SNAKE",
              style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                  letterSpacing: 5)),
          const SizedBox(height: 20),
          // Only High Score is shown here
          Text("High Score: $highScore",
              style: const TextStyle(fontSize: 24, color: Colors.white70)),
          const SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
            ),
            onPressed: startGame,
            child: const Text("PLAY",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget buildGameStructure() {
    return Column(
      children: [
        // 1. Game Score Panel (Only visible when playing)
        Container(
          height: 80,
          color: Colors.grey[900],
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 20),
          child: Text("Score: $score",
              style: const TextStyle(
                  fontSize: 28,
                  color: Colors.orangeAccent,
                  fontWeight: FontWeight.bold)),
        ),

        // 2. The Game Area
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate grid dynamically every time the game view is built
              double itemWidth = constraints.maxWidth / squaresPerRow;
              squaresPerCol = (constraints.maxHeight / itemWidth).floor();

              return GestureDetector(
                onVerticalDragUpdate: (details) {
                  if (details.delta.dy > 0 && currentDirection != Direction.up)
                    currentDirection = Direction.down;
                  else if (details.delta.dy < 0 &&
                      currentDirection != Direction.down)
                    currentDirection = Direction.up;
                },
                onHorizontalDragUpdate: (details) {
                  if (details.delta.dx > 0 &&
                      currentDirection != Direction.left)
                    currentDirection = Direction.right;
                  else if (details.delta.dx < 0 &&
                      currentDirection != Direction.right)
                    currentDirection = Direction.left;
                },
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: squaresPerRow * squaresPerCol,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: squaresPerRow),
                  itemBuilder: (context, index) {
                    // Draw Walls
                    if (isWall(index)) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[700],
                          border:
                          Border.all(color: Colors.transparent, width: 2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }

                    // Draw Snake
                    if (snakePos.contains(index)) {
                      // Head
                      if (index == snakePos.last) {
                        return Container(
                          decoration: BoxDecoration(
                              color: Colors.orange[400],
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: const [
                                BoxShadow(
                                    color: Colors.black54,
                                    blurRadius: 4,
                                    offset: Offset(2, 2))
                              ]),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 6),
                              Container(
                                  width: 4,
                                  height: 4,
                                  decoration: const BoxDecoration(
                                      color: Colors.black,
                                      shape: BoxShape.circle)),
                            ],
                          ),
                        );
                      }
                      // Body
                      return Center(
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.deepOrange[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }

                    // Draw Food
                    if (index == foodPos) {
                      return Container(
                        color: _getGrassColor(index),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 16,
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFF9C4),
                                borderRadius: BorderRadius.circular(15),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 2,
                                      offset: Offset(1, 1))
                                ]),
                          ),
                        ),
                      );
                    }

                    // Draw Grass
                    return Container(color: _getGrassColor(index));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Color _getGrassColor(int index) {
    final random = Random(index);
    List<Color> grassShades = [
      const Color(0xFF2E7D32),
      const Color(0xFF1B5E20),
      const Color(0xFF33691E),
      const Color(0xFF225522),
      const Color(0xFF1e4d2b),
    ];
    return grassShades[random.nextInt(grassShades.length)];
  }
}
