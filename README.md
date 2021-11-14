# PixelArtGenerator

Heavily inspired by: https://lospec.com/procedural-pixel-art-generator/  

![Screenshot_2021-11-14-10-41-10](https://user-images.githubusercontent.com/25201406/141675741-03dbba80-a964-44e3-bd9b-c07bffc9792f.png)

Transparency equals chance to be drawn any pixel with 0.5 alpha will have 50 % chance to be drawn, 0.2 alpha equals 20 % and so on.  
Multiple layers are supported via specifying layer width and supplying an image where all layers are saved next to each other as a horizontal image.  
It's also possible to outline the resulting image, remove stray pixels, add mirroring.  
Color mapping is also included, where the mapped color is either color or array of colors, although one may prefer color mapping via custom shaders.

# Licence
Licensed under the [MIT license](LICENSE.md).