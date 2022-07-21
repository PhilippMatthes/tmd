from tensorflow import keras
from tensorflow.keras import layers


def make_lstm(input_shape, output_classes):
    """
    Basic LSTM model without Non-Shallow feature encoding.
    """
    model = keras.Sequential()
    model.add(layers.LSTM(100, input_shape=input_shape))
    model.add(layers.Dropout(0.5)) # Avoid LSTM overfitting
    model.add(layers.Dense(100, activation='relu'))
    model.add(layers.Dense(output_classes, activation='softmax'))
    return model
