import sys
from pathlib import Path
from PySide6.QtCore import Qt
from PySide6.QtWidgets import (
    QApplication, 
    QFrame,
    QLabel, 
    QMainWindow, 
    QPushButton,
    QSlider, 
    QHBoxLayout, 
    QVBoxLayout,
    QWidget
)

class EqualizerBand(QWidget):
    """A single continuous slider column with a dB readout and band label"""
    
    def __init__(self, band_name: str, min_db: float = -12.0, max_db: float = 12.0):
        super().__init__()
        self.band_name = band_name
        self.precision = 10.0
        
        self.value_label = QLabel("0.0dB")
        self.value_label.setObjectName("ValueLabel")
        self.value_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.value_label.setFixedWidth(54)
        
        self.slider = QSlider(Qt.Orientation.Vertical)
        self.slider.setMinimum(int(min_db * self.precision))
        self.slider.setMaximum(int(max_db * self.precision))
        self.slider.setValue(0)
        self.slider.valueChanged.connect(self.on_value_changed)
        
        self.band_label = QLabel(band_name)
        self.band_label.setObjectName("BandLabel")
        self.band_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        layout = QVBoxLayout(self)
        layout.setContentsMargins(4, 8, 4, 8)
        layout.setSpacing(10)
        layout.addWidget(self.value_label, alignment=Qt.AlignmentFlag.AlignHCenter)
        layout.addWidget(self.slider, alignment=Qt.AlignmentFlag.AlignHCenter)
        layout.addWidget(self.band_label, alignment=Qt.AlignmentFlag.AlignHCenter)

class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("QSlider Test")
        self.resize(200, 400)
        
        self.precision = 100.0
        min_float = 0.0
        max_float = 2.0
        initial_float = 1.0
        
        self.slider = QSlider(Qt.Orientation.Vertical)
        self.slider.setMinimum(int(min_float * self.precision))
        self.slider.setMaximum(int(max_float * self.precision))
        self.slider.setValue(int(initial_float * self.precision))
        
        qss_path = Path(__file__).parent / "style.qss"
        if qss_path.exists():
            self.slider.setStyleSheet(qss_path.read_text(encoding="utf-8"))
        
        self.label = QLabel(f"{initial_float:.2f}")
        self.label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        
        self.slider.valueChanged.connect(self.on_value_changed)
        
        layout = QHBoxLayout()
        layout.addWidget(self.slider)
        layout.addWidget(self.label)
        
        container = QWidget()
        container.setLayout(layout)
        self.setCentralWidget(container)
    
    def on_value_changed(self, value: int) -> None:
        float_value = value / self.precision
        self.label.setText(f"{float_value:.2f}")

def main() -> None:
    app = QApplication(sys.argv)
    window = MainWindow()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()