#!/bin/bash

# 記錄執行腳本前的資料夾
ORIGINAL_DIR=$(pwd)

# 設定 Web 伺服器的根目錄
WEB_ROOT="/home/moos-dawg/moos-dawg-2024/GUI"
cd "$WEB_ROOT" || exit 1  # 若資料夾不存在則結束腳本

# 啟動 rosbridge_server (WebSocket server for ROS)
echo "Starting ROSBridge WebSocket server (rosrun)..."
rosrun rosbridge_server rosbridge_websocket.py _address:=0.0.0.0 _port:=8002 __name:=rosbridge_ws_8002 &
ROSBRIDGE_PID=$!
echo "ROSBridge WebSocket server started with PID $ROSBRIDGE_PID"

# 啟動 Python HTTP 靜態伺服器，指定根目錄
echo "Starting Python HTTP server on port 8000..."
python3 -m http.server 8000 --directory "$WEB_ROOT" &
HTTP_SERVER_PID=$!
echo "Python HTTP server started with PID $HTTP_SERVER_PID, serving files from $WEB_ROOT"

# 啟動 tileserver-gl-light
echo "Starting tileserver-gl-light (port 5002, config.json)..."
tileserver-gl-light -p 5002 -c /home/moos-dawg/moos-dawg-2024/GUI/map/config.json &
TILESERVER_PID=$!
echo "tileserver-gl-light started with PID $TILESERVER_PID"

# 提示用戶服務已啟動
echo "All services are up and running:"
echo " - ROSBridge WebSocket: ws://0.0.0.0:8002"
echo " - Static HTTP server: http://0.0.0.0:8000/main.html"
echo " - tileserver-gl-light: http://0.0.0.0:5002"

echo "Press [CTRL+C] to stop all services..."

# 設置 trap：當收到 Ctrl+C 或腳本退出時，停止所有服務並回到原本目錄
trap 'echo "Stopping services..."; \
      kill $ROSBRIDGE_PID $HTTP_SERVER_PID $TILESERVER_PID; \
      echo "All services stopped."; \
      cd "$ORIGINAL_DIR"; \
      echo "Returned to original directory: $ORIGINAL_DIR";' SIGINT EXIT

# 主程序阻塞，等待所有後台程式結束
wait

# 到這裡代表所有後台程式都已結束（包含手動 Ctrl+C 或正常退出）
echo "All services have ended."

# 回到原本的資料夾
cd "$ORIGINAL_DIR"
echo "Returned to original directory: $ORIGINAL_DIR"

# 啟動交互式 Shell，不退出容器或終端
exec bash
