import streamlit as st
from PIL import Image
import joblib
import numpy as np
import matplotlib.pyplot as plt
import math

from skimage.io import imread
from skimage.transform import rescale
from skimage.util import invert

from sklearn.pipeline import Pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.svm import SVC

st.sidebar.header("Predict your digit", divider='blue')
st.sidebar.write(
    "This app predicts your hand-written digit. " 
    "Draw a digit (0-9) on a piece of paper and use your web camera."
    )

# Place camera frame in the sidebar for easier visuality when taking a photo 
with st.sidebar:
    img_input = st.camera_input("Take a photo by clicking below")

# Checkbox to show steps
st.sidebar.subheader("Check to show steps")
chk = st.sidebar.checkbox("Show steps")

# Prediction text
cols1, cols2 = st.columns([0.8, 0.2])
with cols1:
    st.title("Your digit is predicted as:")
    
# If photo is taken
if img_input:
    # Convert to grayscale and invert
    img_gray = imread(img_input, as_gray=True)
    img_inv = invert(img_gray)
    # Normalize to range of 0-255
    img_min = np.amin(img_inv)
    img_max = np.amax(img_inv)
    img_norm = (img_inv - img_min) * 255.0 / (img_max - img_min)
    # mask with 1 if value > 160 and 0 otherwise
    mask = (img_norm > 160).astype(int)  
    img_masked = img_norm * mask
    # Centering and resizing by cutting out digit and adding to new matrix
    h = img_masked.shape[0] # height
    w = img_masked.shape[1] # width
    dig_h = []
    for i in range(h):
        if np.sum(img_masked[i]) != 0:  # keep non-zero rows
            dig_h.append(img_masked[i])
    dig = np.array(dig_h)
    dig_w = []
    for j in range(w):
        if np.sum(np.array(dig)[:,j], axis=0) != 0: # keep non-zero columns
            dig_w.append(np.array(dig)[:,j])
    new = np.array(dig_w).T
    height = new.shape[0] # height of new digit 
    # rescale to height 20
    new_small = rescale(new, 20/height)
    final_img = np.zeros((28,28))  # creating a 28x28 matrix with only zeros
    w_small = new_small.shape[1]  # width of cut out digit
    h_small = new_small.shape[0]  # height of cut out digit
    margin = 14 - math.floor(w_small/2)  # margin, outside of digit
    final_img[4:4+h_small, margin:margin+w_small] = new_small  # adding digit matrix
    # same flattened shape as training data
    img_flat = final_img.flatten().reshape(-1,1).T
    # load model to transform and predict digit with
    model = joblib.load('model.joblib')
    prediction = model.predict(img_flat)

    with cols2:
        st.title(f":blue[{prediction[0]}]")

# create columns to show pictures side by side
col1, col2, col3, col4 = st.columns(4, gap="small")
#  If checkbox is activated
if chk:
    with col1:
        # show original picture as grayscale
        st.subheader("Step 1")
        st.image(img_gray)
        st.write("Original photo in grayscale")
    with col2:
        # show picture with inverted colors
        st.subheader("Step 2")
        st.image(img_inv)
        st.write("Inverted colors")   
    with col3:
        # show picture with masked background
        st.subheader("Step 3")
        st.image(img_masked/255, clamp=True)
        st.write("Masked background to black")
    with col4:
        # show resized (28x28)
        st.subheader("Step 4")
        st.image(final_img/255, width=120)
        st.write("Digit centered and rescaled to 28x28")