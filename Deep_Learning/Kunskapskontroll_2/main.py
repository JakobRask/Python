import streamlit as st
from streamlit_webrtc import webrtc_streamer, RTCConfiguration, WebRtcMode, VideoProcessorBase
from keras.models import load_model
from tensorflow.keras.utils import img_to_array
from keras.preprocessing import image
import cv2
import av
import numpy as np

cascade = cv2.CascadeClassifier(r'haarcascade_frontalface_default.xml')
model = load_model(r'model.h5')
model_2 = load_model(r'model_fine.keras')

emotion_labels = ['Angry', 'Disgust', 'Fear', 'Happy', 'Neutral', 'Sad', 'Surprise']

# if deploying on cloud use RTC
RTC_CONFIG = RTCConfiguration({"iceServers": [{"urls": ["stun:stun.l.google.com:19302"]}]})

# Prediction using model build from scratch
class Processor(VideoProcessorBase):
    def recv(self, frame):
        img = frame.to_ndarray(format = "bgr24")
        gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
        faces = cascade.detectMultiScale(image = gray, scaleFactor = 1.3, minNeighbors = 5)
    
        # draw rectangle with prediction for faces
        for (x, y, w, h) in faces:
            cv2.rectangle(img, (x,y), (x+w, y+h), (0, 255, 0), 2)
            roi_gray = gray[y:y+h, x:x+w]
            roi_gray = cv2.resize(roi_gray, (48, 48), interpolation=cv2.INTER_AREA)
            if np.sum([roi_gray]) != 0:
                roi = roi_gray.astype('float')
                roi = img_to_array(roi)
                roi = np.expand_dims(roi, axis = 0)
                prediction = model.predict(roi)[0]
                label = emotion_labels[prediction.argmax()]
                label_position = (x, y-10)
                cv2.putText(img, label, label_position, cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 0), 2)
            
        return av.VideoFrame.from_ndarray(img, format = "bgr24")


# Prediction using fine-tuned pre-trained model
class Processor_2(VideoProcessorBase):
    def recv(self, frame):
        img = frame.to_ndarray(format = "bgr24")
        faces = cascade.detectMultiScale(image = img, scaleFactor = 1.3, minNeighbors = 5)
    
        # draw rectangle with prediction for faces
        for (x, y, w, h) in faces:
            cv2.rectangle(img, (x, y), (x+w, y+h), (0, 255, 255), 2)
            roi_img = img[y:y+h, x:x+w]
            roi_img = cv2.resize(roi_img, (224, 224), interpolation=cv2.INTER_AREA)
            if np.sum([roi_img]) != 0:
                roi = roi_img.astype('float')
                roi = img_to_array(roi)
                roi = np.expand_dims(roi, axis = 0)
                prediction = model_2.predict(roi)[0]
                label = emotion_labels[prediction.argmax()]
                label_position = (x, y-10)
                cv2.putText(img, label, label_position, cv2.FONT_HERSHEY_SIMPLEX, 1, (0, 255, 255), 2)
            
        return av.VideoFrame.from_ndarray(img, format = "bgr24")      


# sidebar choices
def main():
    st.sidebar.header("Predict your expression", divider = 'blue')
    with st.sidebar:
        choice = st.sidebar.selectbox("Select option", ["Expression recognition", "Info"])
        st.write("It may take a moment for the videos to run smoothly.")
    if choice == "Expression recognition":
        st.header("Facial expression recognition with webcam")
        st.write()
        cols = st.columns(2)
        with cols[0]: 
            st.subheader("Model build from scratch")
            webrtc_streamer(key="model",
                            mode=WebRtcMode.SENDRECV,
                            rtc_configuration = RTC_CONFIG,
                            video_processor_factory = Processor,
                            media_stream_constraints = {"video": True, "audio": False})
        with cols[1]: 
            st.subheader("Fine-tuned MobileNetV2")
            webrtc_streamer(key="model_2", 
                            mode=WebRtcMode.SENDRECV,
                            rtc_configuration = RTC_CONFIG,
                            video_processor_factory = Processor_2,
                            media_stream_constraints = {"video": True, "audio": False})
    elif choice == "Info":
        st.title("About the app")
        st.write("With this app you can predict facial expressions with two different Neural Network models.")
        st.write("The first model is a CNN model built from scratch.")
        st.write("The second model is a pre-trained model, fine-tuned to adapt to this type classification.")
        st.write("By pressing Start on each video you can test one or both of the models.")
    else:
        pass
        
if __name__ == "__main__":
    main()

    
