import cv2
import mediapipe as mp
import os

class PoseDetectorWrapper:
    def __init__(self):
        BaseOptions = mp.tasks.BaseOptions
        PoseLandmarker = mp.tasks.vision.PoseLandmarker
        PoseLandmarkerOptions = mp.tasks.vision.PoseLandmarkerOptions
        VisionRunningMode = mp.tasks.vision.RunningMode

        model_path = os.path.join(os.path.dirname(__file__), 'pose_landmarker_lite.task')
        
        # Check if model exists, warn if not
        if not os.path.exists(model_path):
            print(f"WARNING: Model file not found at {model_path}")
            print(f"To download, visit: https://developers.google.com/mediapipe/solutions/vision/pose_landmarker/")
            print(f"And place the downloaded pose_landmarker_lite.task file in: {os.path.dirname(model_path)}")
            # Create a minimal fallback for testing
            raise FileNotFoundError(
                f"Model file required: {model_path}\n"
                f"Please download from MediaPipe official sources and place in {os.path.dirname(model_path)}"
            )

        options = PoseLandmarkerOptions(
            base_options=BaseOptions(model_asset_path=model_path),
            running_mode=VisionRunningMode.IMAGE
        )
        self.landmarker = PoseLandmarker.create_from_options(options)

    def detect(self, image):
        """
        Detects poses in an OpenCV BGR image.
        """
        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=image_rgb)
        
        detection_result = self.landmarker.detect(mp_image)
        
        if not detection_result.pose_landmarks or len(detection_result.pose_landmarks) == 0:
            return None
            
        return detection_result.pose_landmarks[0]

    def close(self):
        self.landmarker.close()
