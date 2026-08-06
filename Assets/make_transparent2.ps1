Add-Type -AssemblyName System.Drawing
$path = 'C:\Users\avser\OneDrive\Desktop\Nimute\Assets\lifebuoy.png'
$img = [System.Drawing.Bitmap]::FromFile($path)
$w = $img.Width
$h = $img.Height
for($y=0; $y -lt $h; $y++){
    for($x=0; $x -lt $w; $x++){
        $c = $img.GetPixel($x,$y)
        # Check if the pixel is strongly blue but not white/red
        if($c.B -gt 150 -and $c.R -lt 150 -and $c.G -lt 200){
            $img.SetPixel($x,$y, [System.Drawing.Color]::Transparent)
        }
    }
}
$img.Save('C:\Users\avser\OneDrive\Desktop\Nimute\Assets\lifebuoy_transparent.png', [System.Drawing.Imaging.ImageFormat]::Png)
$img.Dispose()
