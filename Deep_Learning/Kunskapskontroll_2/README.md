# Facial Expression Recognition project

The project is based on the Emotion Detection video from Akshit Madan's Youtube channel.  
https://www.youtube.com/watch?v=Bb4Wvl57LIk 
The aim for this project is to build an web-camera app which can recognize 6 different face expressions;
Angry, Disgust, Fear, Happy, Neutral, Sad and Surprise

The app shows real-time predictions from two models.
The first model i build from scratch (same as the one in the video).
The second model is a fine-tuned pre-trained model (MobileNetV2).

Both models have their flaws, but they differ in accuracy for the different expressions.
This makes it interesting to compare the two models with your web-camera and evaluate their predictions yourself.


# Streamlit app

* Download the files and use pip to install streamlit and streamlit_webrtc
* Run main.py from terminal <streamlit run main.py>
