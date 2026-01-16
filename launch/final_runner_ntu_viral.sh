#!/usr/bin/env bash
set -Eeuo pipefail

LOG_DIR="./logs_parallel_$(date +%Y%m%d_%H%M%S)"
mkdir -p "${LOG_DIR}"

TF_LOG="${LOG_DIR}/static_tf.log"
BAG_LOG="${LOG_DIR}/bag_run.log"

echo "[INFO] Logs: ${LOG_DIR}"

# --- Preconditions ---
command -v rosrun >/dev/null 2>&1 || {
  echo "[ERROR] 'rosrun' not found in PATH. Did you source your ROS1 setup.bash?"
  echo "        Example: source /opt/ros/noetic/setup.bash"
  exit 127
}

if [[ ! -f ./run_one_bag_ntu_viral.sh ]]; then
  echo "[ERROR] ./run_one_bag_ntu_viral.sh not found in current directory: $(pwd)"
  exit 2
fi

if [[ ! -x ./run_one_bag_ntu_viral.sh ]]; then
  echo "[ERROR] ./run_one_bag_ntu_viral.sh is not executable."
  echo "        Run: chmod +x ./run_one_bag_ntu_viral.sh"
  exit 126
fi

# --- Start TF publisher first ---
echo "[INFO] Starting static_transform_publisher..."
rosrun tf2_ros static_transform_publisher \
  0 0 0 \
  0 3.141592653589793 0 \
  camera_init camera_init_flipped \
  >"${TF_LOG}" 2>&1 &
TF_PID=$!
echo "[INFO] static_transform_publisher PID=${TF_PID}"

cleanup() {
  echo "[INFO] Cleaning up..."
  if kill -0 "${TF_PID}" 2>/dev/null; then
    kill "${TF_PID}" 2>/dev/null || true
    wait "${TF_PID}" 2>/dev/null || true
  fi
}
trap cleanup EXIT INT TERM

# Give TF a moment to start
sleep 0.5

# If TF died immediately, show log
if ! kill -0 "${TF_PID}" 2>/dev/null; then
  echo "[ERROR] static_transform_publisher exited immediately."
  echo "-------- ${TF_LOG} (last 80 lines) --------"
  tail -n 80 "${TF_LOG}" || true
  exit 1
fi

# --- Start bag runner in parallel ---
echo "[INFO] Starting run_one_bag_ntu_viral.sh..."
./run_one_bag_ntu_viral.sh \
  /data/fastLio_ros1/outputs \
  /dataset \
  /data/fastLio_ros1/src/FAST_LIO \
  eee_01 \
  false true 400 0 0 0 0.75 -1 \
  >"${BAG_LOG}" 2>&1 &
BAG_PID=$!
echo "[INFO] run_one_bag_ntu_viral.sh PID=${BAG_PID}"

# If bag script dies immediately, show log
sleep 0.5
if ! kill -0 "${BAG_PID}" 2>/dev/null; then
  echo "[ERROR] run_one_bag_ntu_viral.sh exited immediately."
  echo "-------- ${BAG_LOG} (last 120 lines) --------"
  tail -n 120 "${BAG_LOG}" || true
  exit 1
fi

# Wait for bag script to finish (TF stays up)
wait "${BAG_PID}" || {
  RC=$?
  echo "[ERROR] Bag script exited with code ${RC}"
  echo "-------- ${BAG_LOG} (last 200 lines) --------"
  tail -n 200 "${BAG_LOG}" || true
  exit "${RC}"
}

echo "[INFO] Bag script finished normally."
echo "[INFO] TF publisher will be stopped by cleanup handler."
