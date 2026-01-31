import QtQuick
import "../" as RootDir

QtObject {
    id: root
    property bool isDarkMode: true // Kept for compatibility

    // Instantiate dynamic theme
    property RootDir.Colors c: RootDir.Colors {}

    // 1) Surfaces
    // Background of the main panel/hub
    readonly property color bgMain: Qt.rgba(c.background.r, c.background.g, c.background.b, 0.95)
    
    // Background of cards/groups
    readonly property color bgCard: Qt.rgba(c.color0.r, c.color0.g, c.color0.b, 0.6)
    
    // Background of interactive items (buttons)
    readonly property color bgItem: Qt.rgba(c.color8.r, c.color8.g, c.color8.b, 0.3)
    
    // Background of widgets
    readonly property color bgWidget: Qt.rgba(c.color0.r, c.color0.g, c.color0.b, 0.8)

    // 2) Text
    readonly property color textPrimary: c.foreground
    readonly property color textSecondary: c.color8 // Muted text
    readonly property color textOnAccent: c.background // Text on accent buttons

    // 3) Accents
    readonly property color accent: c.color2        // Primary accent
    readonly property color accentSlider: c.color2  // Slider fill
    readonly property color accentRed: c.color1     // Destructive/Red

    // 4) Lines, hovers, misc
    readonly property color border: Qt.rgba(c.foreground.r, c.foreground.g, c.foreground.b, 0.15)
    readonly property color outline: Qt.rgba(c.foreground.r, c.foreground.g, c.foreground.b, 0.1)

    readonly property color subtleFill: Qt.rgba(c.foreground.r, c.foreground.g, c.foreground.b, 0.05)
    readonly property color subtleFillHover: Qt.rgba(c.foreground.r, c.foreground.g, c.foreground.b, 0.15)
    readonly property color hoverSpotlight: Qt.rgba(c.foreground.r, c.foreground.g, c.foreground.b, 0.1)
}