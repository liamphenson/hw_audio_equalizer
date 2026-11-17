"""The desktop equalizer's 13-band attenuation controls."""

import sys
from pathlib import Path

from PySide6.QtCore import Qt, Signal
from PySide6.QtGui import QColor, QPainter, QPen
from PySide6.QtWidgets import (
    QApplication,
    QFrame,
    QHBoxLayout,
    QLabel,
    QMainWindow,
    QPushButton,
    QSizePolicy,
    QSlider,
    QVBoxLayout,
    QWidget,
)


class LevelScale(QWidget):
    """A shared reference scale aligned with the sliders' travel."""

    def __init__(self):
        super().__init__()
        self.setFixedWidth(46)
        self.setMinimumHeight(160)

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setPen(QPen(QColor("#7e8b99")))
        font = self.font()
        font.setPixelSize(11)
        painter.setFont(font)
        # The handle is 22 px tall, so its center stops 11 px from each end.
        travel = self.height() - 22
        for index, text in enumerate(("1.00", "0.75", "0.50", "0.25", "0.00")):
            y = round(11 + travel * index / 4)
            painter.drawText(0, y - 8, 32, 16, Qt.AlignRight | Qt.AlignVCenter, text)
            painter.drawLine(39, y, 45, y)


class EqualizerBand(QWidget):
    """One normalized attenuation control, with its value below the fader."""

    attenuationChanged = Signal(float)
    PRECISION = 100

    def __init__(self, band_name: str):
        super().__init__()
        self.setObjectName("EqualizerBand")
        self.setAttribute(Qt.WidgetAttribute.WA_StyledBackground, True)
        self.setSizePolicy(QSizePolicy.Expanding, QSizePolicy.Expanding)
        self.setMinimumWidth(56)

        self.band_label = QLabel(band_name)
        self.band_label.setObjectName("BandLabel")
        self.band_label.setAlignment(Qt.AlignCenter)
        self.band_label.setFixedHeight(24)

        self.slider = QSlider(Qt.Orientation.Vertical)
        self.slider.setRange(0, self.PRECISION)
        self.slider.setValue(self.PRECISION)
        self.slider.setSingleStep(1)
        self.slider.setPageStep(10)
        self.slider.setMinimumHeight(160)
        self.slider.setFixedWidth(40)
        self.slider.setSizePolicy(QSizePolicy.Fixed, QSizePolicy.Expanding)
        self.slider.setAccessibleName(f"Band {band_name} attenuation")
        self.slider.setAccessibleDescription(
            "From 0, muted, to 1, full level. Use arrow keys to adjust."
        )

        self.value_label = QLabel("1.00")
        self.value_label.setObjectName("ValueLabel")
        self.value_label.setAlignment(Qt.AlignCenter)
        self.value_label.setFixedSize(52, 34)
        self.slider.valueChanged.connect(self.on_value_changed)
        self._update_tooltip()

        layout = QVBoxLayout(self)
        layout.setContentsMargins(2, 8, 2, 8)
        layout.setSpacing(18)
        layout.addWidget(self.band_label)
        layout.addWidget(self.slider, 1, Qt.AlignHCenter)
        layout.addWidget(self.value_label, 0, Qt.AlignHCenter)

    @property
    def attenuation(self) -> float:
        return self.slider.value() / self.PRECISION

    def on_value_changed(self, value: int) -> None:
        attenuation = value / self.PRECISION
        self.value_label.setText(f"{attenuation:.2f}")
        self._update_tooltip()
        self.attenuationChanged.emit(attenuation)

    def _update_tooltip(self) -> None:
        self.slider.setToolTip(f"Band {self.band_label.text()} · {self.attenuation:.2f} attenuation")


class MainWindow(QMainWindow):
    def __init__(self) -> None:
        super().__init__()
        self.setWindowTitle("Audio Equalizer")
        self.setMinimumSize(1000, 620)
        self.resize(1220, 740)
        self.setStyleSheet(
            Path(__file__).with_name("style.qss").read_text(encoding="utf-8")
        )

        container = QWidget()
        container.setObjectName("AppSurface")
        self.setCentralWidget(container)
        layout = QVBoxLayout(container)
        layout.setContentsMargins(36, 32, 36, 24)
        layout.setSpacing(24)

        header = QHBoxLayout()
        heading = QVBoxLayout()
        heading.setSpacing(8)
        title = QLabel("Equalizer Control")
        title.setObjectName("Title")
        heading.addWidget(title)
        header.addLayout(heading)
        header.addStretch()

        self.reset_button = QPushButton("Reset all")
        self.reset_button.setCursor(Qt.PointingHandCursor)
        self.reset_button.setToolTip("Restore all 13 bands to 1.00")
        self.reset_button.clicked.connect(self.reset_bands)
        header.addWidget(self.reset_button, 0, Qt.AlignVCenter)
        layout.addLayout(header)

        panel = QFrame()
        panel.setObjectName("ControlPanel")
        panel_layout = QVBoxLayout(panel)
        panel_layout.setContentsMargins(22, 22, 22, 20)
        panel_layout.setSpacing(18)

        panel_header = QHBoxLayout()
        panel_title = QLabel("BAND ATTENUATION")
        panel_title.setObjectName("PanelTitle")
        panel_header.addWidget(panel_title)
        panel_header.addStretch()
        panel_layout.addLayout(panel_header)
        panel_layout.addWidget(self._divider())

        controls = QHBoxLayout()
        controls.setSpacing(8)
        scale_layout = QVBoxLayout()
        # Match each band's header, readout, spacing, and outer margins.
        scale_layout.setContentsMargins(0, 50, 0, 60)
        scale_layout.addWidget(LevelScale(), 1)
        controls.addLayout(scale_layout)

        self.bands = []
        for index in range(13):
            band = EqualizerBand(f"{(index+1):.2f}")
            self.bands.append(band)
            controls.addWidget(band, 1)
        panel_layout.addLayout(controls, 1)
        panel_layout.addWidget(self._divider())

        panel_footer = QHBoxLayout()
        factor_label = QLabel("ATTENUATION FACTOR")
        factor_label.setObjectName("PanelMeta")
        range_label = QLabel("0.00  Muted     /     1.00  Full level")
        range_label.setObjectName("PanelMeta")
        panel_footer.addWidget(factor_label)
        panel_footer.addStretch()
        panel_footer.addWidget(range_label)
        panel_layout.addLayout(panel_footer)
        layout.addWidget(panel, 1)

        footer = QHBoxLayout()
        hint = QLabel("Select a slider, then use ↑ / ↓ for precise adjustments.")
        hint.setObjectName("Footer")
        footer.addWidget(hint)
        footer.addStretch()
        layout.addLayout(footer)

    @staticmethod
    def _divider() -> QFrame:
        divider = QFrame()
        divider.setObjectName("Divider")
        divider.setFixedHeight(1)
        return divider

    def reset_bands(self) -> None:
        for band in self.bands:
            band.slider.setValue(band.PRECISION)


def main() -> None:
    app = QApplication(sys.argv)
    app.setApplicationName("Audio Equalizer")
    app.setStyle("Fusion")
    window = MainWindow()
    window.show()
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
