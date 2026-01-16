docker run --rm -it \
  --name ros-noetic-fastlio \
  --gpus all \
  --network host \
  --ipc=host \
  -e DISPLAY \
  -e QT_X11_NO_MITSHM=1 \
  -e __GLX_VENDOR_LIBRARY_NAME=nvidia \
  -e __NV_PRIME_RENDER_OFFLOAD=1 \
  -e NVIDIA_VISIBLE_DEVICES=all \
  -e NVIDIA_DRIVER_CAPABILITIES=compute,utility,graphics,display,video \
  -e XDG_RUNTIME_DIR=/run/user/$(id -u) \
  -e ROS_DOMAIN_ID=77 \
  -v /run/user/$(id -u):/run/user/$(id -u) \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v $HOME/.Xauthority:/root/.Xauthority:ro \
  -v /home/buraks/workspace:/data:rw \
  -v /media/buraks/T71/PHD/Dataset/NTU_viral_dataset:/dataset:rw \
  buraks1/ros-noetic-custom:fastlio \
  bash
