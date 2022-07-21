from tensorflow import keras
from tensorflow.keras import layers


def make_conv_lstm(input_shape, output_classes):
    """
    Convolutional LSTM Model.
    """
    model = keras.Sequential()
    # Convolutional encoder (non-shallow features)
    model.add(layers.Conv1D(64, kernel_size=3, activation='relu', input_shape=input_shape))
    # Time series classification
    model.add(layers.LSTM(128))
    model.add(layers.Dense(64))
    model.add(layers.Dense(1, activation='sigmoid'))
    return model
