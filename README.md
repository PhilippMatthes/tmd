# Mobile Transport Mode Detection

This repository provides experiments, models and an iOS prototype for transport mode detection on smartphones. It is part of the paper submission: "Selecting Resource-Efficient ML Models for Transport Mode Detection on Mobile Devices" at the 2022 IEEE International Conference on Internet of Things and Intelligence Systems. 

# Model Download

| Model ID | Type | Pooling | Optimizer | Optimization | Depth | LR | Val. Acc. (%) | Download |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
|4ad2e7|1d ResNetV1|max|adam|Pruning & Separable Layers|2|0.010|84.91|[Google Drive](https://drive.google.com/file/d/1-JH0K0vsLOuqiTp2PAIPoLXRUyvvk36p/view?usp=sharing)|
|4ad2e7|1d ResNetV1|max|adam|Pruning|2|0.010|84.38|[Google Drive](https://drive.google.com/file/d/1Dj7Op4LArlK0gnkGpqvbj6uetNlxNSL3/view?usp=sharing)|
|4ad2e7|1d ResNetV1|max|adam|-|2|0.010|84.34|[Google Drive](https://drive.google.com/file/d/1-CyUZTibwya5l2j2l_StHtYe_u2tOJ04/view?usp=sharing)|
|6af8a1|1d ResNetV1|max|adam|-|4|0.010|84.18|[Google Drive](https://drive.google.com/file/d/1-LkSVciKyGQkO6YyAqHazqArNhfgc5U3/view?usp=sharing)|
|7cfd66|1d ResNetV1|max|sgd|-|2|0.100|84.18|[Google Drive](https://drive.google.com/file/d/1-8kybhtQut8Mz-6zz0UfFssz_t_yqCGQ/view?usp=sharing)|
|968ca3|1d ResNetV1|max|sgd|-|2|0.100|84.03|[Google Drive](https://drive.google.com/file/d/1-1UjIR3Qs-2oZD49AVnbmPpeLG05iKDJ/view?usp=sharing)|
|e6c367|1d ResNetV1|avg|adam|-|3|0.001|83.69|[Google Drive](https://drive.google.com/file/d/1-1Uurz7PfFuw9-wdV-DfH7EQGEFgopZs/view?usp=sharing)|
|998822|1d ResNetV2|max|sgd|-|2|0.010|82.92|[Google Drive](https://drive.google.com/file/d/1-_hmv7INFEIGTRC2Lz7H8NJCEC22zFLI/view?usp=sharing)|
|752315|2d ResNetV2|avg|rmsprop|-|2|0.010|81.33|[Google Drive](https://drive.google.com/file/d/1-4n6KBRXdm2Dz-D6tZHM4NYsf-d40FSj/view?usp=sharing)|
|35d171|2d ResNetV1|avg|adam|-|2|0.010|81.07|[Google Drive](https://drive.google.com/file/d/1-8DgA9znYzIKrfPmHxaCgkz8VPFRaswu/view?usp=sharing)|
|ea7037|1d ResNetV1|avg|adam|-|3|0.001|81.01|[Google Drive](https://drive.google.com/file/d/1-ROstQ3WI8ZtCy8xDzDMg-UhFlT8wC8s/view?usp=sharing)|
|cb5048|2d ResNetV1|max|adam|-|2|0.010|78.96|[Google Drive](https://drive.google.com/file/d/1-00pwU2B3yer4jPU4Wp_oP2OIVCNwB_5/view?usp=sharing)|

# Repository Structure

- [`prototype`](prototype): Implementation of our iOS prototype, used for resource profiling
- [`shl-data-analysis.ipynb`](shl-data-analysis.ipynb): Initial SHL dataset exploration and selection of scalers
- [`shl-power-transformers.ipynb`](shl-power-transformers.ipynb): Fitting of power transformers for individual sensors on the SHL dataset
- [`shl-deep-learning-autoencoder.ipynb`](shl-deep-learning-autoencoder.ipynb): Autoencoder prototyping for deep features
- [`shl-deep-learning-prototyping-results.ipynb`](hl-deep-learning-prototyping-results.ipynb): Prototyping of some of the deep learning architectures
- [`shl-dl-architectures`](shl-dl-architectures): Prototype deep learning architectures used for base model selection
- [`shl-traditional-features.ipynb`](shl-traditional-features.ipynb): Prototyping of traditional architectures and shallow features
- [`shl-deep-learning-timeseries.ipynb`](shl-deep-learning-timeseries.ipynb): ResNet model architecture definition, grid-search, export and optimization
- [`shl-deep-learning-timeseries-results.ipynb`](shl-deep-learning-timeseries-results.ipynb): Results evaluation of tradeoff analysis
- [`shl-stft-visualization.ipynb`](shl-stft-visualization.ipynb): Visualization of STFT on the SHL data

# License

`MIT`
