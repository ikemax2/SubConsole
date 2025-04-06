//
//  default.metal
//  SubConsole
//
//  ©︎ 2025 TAKEHITO IKEMA
//
#include <metal_stdlib>
#include <simd/simd.h>

using namespace metal;

typedef struct {
    float4 position [[position]];
    float2 texCoord;
} ImageColorInOut;


kernel void kernel_passthrough(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]])
{
    float4 inColor   = inTexture.read(gid);
    outTexture.write(inColor, gid);
}

vertex ImageColorInOut vertexShader(uint vid [[ vertex_id ]]) {
    const ImageColorInOut vertices[4] = {
        { float4(-1, -1, 0, 1), float2(0, 1) },
        { float4(1, -1, 0, 1), float2(1, 1) },
        { float4(-1, 1, 0, 1), float2(0, 0) },
        { float4(1, 1, 0, 1), float2(1, 0) },
    };
    return vertices[vid];
}

fragment float4 fragmentShader420v(ImageColorInOut in [[ stage_in ]],
                                   texture2d<float, access::sample> capturedImageTextureY [[ texture(0) ]],
                                   texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(1) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
   const float4x4 ycbcrToRGBTransform = float4x4(
       float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
       float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
       float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
       float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
   );
    
   float4 baseYUVColor = float4(capturedImageTextureY.sample(colorSampler, in.texCoord).r,
                                capturedImageTextureCbCr.sample(colorSampler, in.texCoord).rg,
                                1.0f);

   // yuv video range to full range
   baseYUVColor.r = (baseYUVColor.r - (16.0f/255.0f)) * (255.0f/(235.0f-16.0f));
   baseYUVColor.g = (baseYUVColor.g - (16.0f/255.0f)) * (255.0f/(240.0f-16.0f));
   baseYUVColor.b = (baseYUVColor.b - (16.0f/255.0f)) * (255.0f/(240.0f-16.0f));

   // yuv to rgb
   float4 baseColor = ycbcrToRGBTransform * baseYUVColor;
        
    return baseColor;
}

fragment float4 fragmentShader420f(ImageColorInOut in [[ stage_in ]],
                                   texture2d<float, access::sample> capturedImageTextureY [[ texture(0) ]],
                                   texture2d<float, access::sample> capturedImageTextureCbCr [[ texture(1) ]])
{
    constexpr sampler colorSampler(mip_filter::linear,
                                   mag_filter::linear,
                                   min_filter::linear);
   const float4x4 ycbcrToRGBTransform = float4x4(
       float4(+1.0000f, +1.0000f, +1.0000f, +0.0000f),
       float4(+0.0000f, -0.3441f, +1.7720f, +0.0000f),
       float4(+1.4020f, -0.7141f, +0.0000f, +0.0000f),
       float4(-0.7010f, +0.5291f, -0.8860f, +1.0000f)
   );
    
   float4 baseYUVColor = float4(capturedImageTextureY.sample(colorSampler, in.texCoord).r,
                                capturedImageTextureCbCr.sample(colorSampler, in.texCoord).rg,
                                1.0f);

   // yuv to rgb
   float4 baseColor = ycbcrToRGBTransform * baseYUVColor;
        
    return baseColor;
}

fragment float4 fragmentShaderBGRA(ImageColorInOut in [[ stage_in ]],
                                   texture2d<float, access::sample> capturedImageTextureBGRA [[ texture(0) ]])
{

    constexpr sampler colorSampler;
    float4 baseBGRColor = float4(capturedImageTextureBGRA.sample(colorSampler, in.texCoord).rgb,
                                 1.0f);
        
    return baseBGRColor;
}



// Outputs a triangle that covers the full screen.
//
// The `vid` input should be in the range [0, 2].
vertex ImageColorInOut FSQ_VS_V4T2(uint vid [[vertex_id]])
{
    // These vertices map a triangle to cover a full-screen quad.
    const float2 vertices[] = {
        float2(-1, -1), // bottom left
        float2(3, -1),  // bottom right
        float2(-1, 3),  // upper left
    };
    
    const float2 texcoords[] = {
        float2(0.0, 1.0),  // bottom left
        float2(2.0, 1.0),  // bottom right
        float2(0.0, -1.0), // upper left
    };
    
    ImageColorInOut out;
    out.position = float4(vertices[vid], 1.0, 1.0);
    out.texCoord = texcoords[vid];
    return out;
}

// Copies the input texture to the output.
fragment half4 FSQ_simpleCopy(ImageColorInOut in [[stage_in]],
                              texture2d<half> src [[texture(0)]])
{
#if AAPL_DEFAULT_UPSCALE_LINEAR
    constexpr sampler sampler(min_filter::linear, mag_filter::linear);
#else
    constexpr sampler sampler(min_filter::nearest, mag_filter::nearest);
#endif
    
    half4 sample;

    sample = src.sample(sampler, in.texCoord);

    return sample;
}

