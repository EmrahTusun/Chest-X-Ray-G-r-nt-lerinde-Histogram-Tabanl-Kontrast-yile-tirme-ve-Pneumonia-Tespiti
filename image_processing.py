import cv2

def apply_hist_eq(image_gray):
    return cv2.equalizeHist(image_gray)

def apply_clahe(image_gray):
    clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8,8))
    return clahe.apply(image_gray)