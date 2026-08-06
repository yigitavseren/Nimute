Add-Type -AssemblyName System.Drawing
$path = 'C:\Users\avser\OneDrive\Desktop\Nimute\Assets\lifebuoy.png'
$img = [System.Drawing.Bitmap]::FromFile($path)
$bg = $img.GetPixel(0,0)
$img.MakeTransparent($bg)
$img.Save('C:\Users\avser\OneDrive\Desktop\Nimute\Assets\lifebuoy_transparent.png', [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()
