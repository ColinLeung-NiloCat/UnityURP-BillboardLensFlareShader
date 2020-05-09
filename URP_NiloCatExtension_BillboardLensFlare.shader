//see README here: 
//github.com/ColinLeung-NiloCat/UnityURP-BillboardLensFlareShader

Shader "Universal Render Pipeline/NiloCat Extension/BillBoard LensFlare"
{
    Properties
    {
        //////////////////////////////////////////////////////////////////////////////////////////
        //same name as URP's official shader, so switching material's shader to this will still preserve settings
        //////////////////////////////////////////////////////////////////////////////////////////
        [HDR][MainColor] _BaseColor("BaseColor", Color) = (1,1,1,1)
        _BaseColorIntensity("_BaseColorIntensity", Float) = 1
        [MainTexture] _BaseMap("BaseMap", 2D) = "white" {}
        _RemoveTextureArtifact("_RemoveTextureArtifact", Range(0,0.5)) = 0.003

        //////////////////////////////////////////////////////////////////////////////////////////
        //custom settings
        //////////////////////////////////////////////////////////////////////////////////////////
        [Header(PreMultiply Alpha. Turn it ON only if your texture has correct alpha)]
        [Toggle]_UsePreMultiplyAlpha("_UsePreMultiplyAlpha (recommend _BaseMap's alpha = 'From Gray Scale')", Float) = 0

        [Header(Override Alpha. Use when flare is too bright)]
        [Toggle]_ShouldOverrideAlpha("_ShouldOverrideAlpha", Float) = 0
        _OverrideAlphaUsage("_OverrideAlphaUsage", Range(0,1)) = 1
        _OverrideAlphaTo("_OverrideAlphaTo", Range(0,1)) = 1

        [Header(Depth Occlusion)]
        _LightSourceViewSpaceRadius("_LightSourceViewSpaceRadius", range(0,1)) = 0.05
        _DepthOcclusionTestZBias("_DepthOcclusionTestZBias", range(-1,1)) = -0.001

        [Header(If camera too close Auto fadeout)]
        _StartFadeinDistanceWorldUnit("_StartFadeinDistanceWorldUnit",Float) = 0.05
        _EndFadeinDistanceWorldUnit("_EndFadeinDistanceWorldUnit", Float) = 0.5

        [Header(Optional Flicker animation)]
        [Toggle]_ShouldDoFlicker("_ShouldDoFlicker", FLoat) = 1
        _FlickerAnimSpeed("_FlickerAnimSpeed", Float) = 5
        _FlickResultIntensityLowestPoint("_FlickResultIntensityLowestPoint", range(0,1)) = 0.5
    }

    SubShader
    {
        Tags 
        {
            //lens flare is the artifact inside camera itself, so it should be drawn as late as possible 
            "RenderType" = "Overlay" 
            "Queue" = "Overlay"

            //we need object space vertex position, can't allow dynamic batching
            "DisableBatching" = "True" 

            "IgnoreProjector" = "True"
        }

        //we will do multiple depth tests inside the vertex shader, so turn every Z related setting off
        ZWrite off
        ZTest off

        //Should I expose Blend[][] to properties? - NO! because:
        //this shader is only for lens flare...
        //If we consider HDR, exposing Blend[][] to user will increase many user errors, without reasonable gain

        //Blend OneMinusDstColor One , aka Soft Additive (photoshop's screen blend)
        //will conflict with HDR, so we can't use it

        //Blend One One             //HDR friendly option(1), limited possibility
        Blend One OneMinusSrcAlpha  //HDR friendly option(2), which can produce all option(1)'s result also when alpha = 0

        // Include material cbuffer for all passes. 
        // The cbuffer has to be the same for all passes to make this shader SRP batcher compatible.
        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        TEXTURE2D(_BaseMap);
        SAMPLER(sampler_BaseMap);
        SAMPLER(_CameraDepthTexture);

        CBUFFER_START(UnityPerMaterial)

            float4 _BaseMap_ST;
            half4 _BaseColor;
            half _BaseColorIntensity;
            half _RemoveTextureArtifact;

            float _UsePreMultiplyAlpha;

            float _ShouldOverrideAlpha;
            half _OverrideAlphaUsage;
            half _OverrideAlphaTo;

            float _LightSourceViewSpaceRadius;
            float _DepthOcclusionTestZBias;

            float _StartFadeinDistanceWorldUnit;
            float _EndFadeinDistanceWorldUnit;

            float _FlickerAnimSpeed;
            float _FlickResultIntensityLowestPoint;
            float _ShouldDoFlicker;

        CBUFFER_END

        ENDHLSL

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            struct Attributes
            {
                float4 positionOS   : POSITION;
                float2 uv           : TEXCOORD0;
                half4 color        : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS  : SV_POSITION;
                float2 uv           : TEXCOORD0;
                half4 color         : TEXCOORD1;
            };

            #define COUNT 8 //you can edit to any number(e.g. 1~32), the lower the faster. Keeping this number a const can enable many compiler optimizations

            //we don't need to care performance too much in vertex shader, each flare mesh renderer runs vertex shader 4 times only
            Varyings vert(Attributes IN)
            {
                //regular code, not related to billboard / flare
                Varyings OUT;
                OUT.uv = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.color = IN.color * _BaseColor;
                OUT.color.rgb *= _BaseColorIntensity;

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //make quad look at camera in view space
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                float3 quadPivotPosOS = float3(0,0,0);
                float3 quadPivotPosWS = TransformObjectToWorld(quadPivotPosOS);
                float3 quadPivotPosVS = TransformWorldToView(quadPivotPosWS);

                //get transform.lossyScale using:
                //https://forum.unity.com/threads/can-i-get-the-scale-in-the-transform-of-the-object-i-attach-a-shader-to-if-so-how.418345/
                float2 scaleXY_WS = float2(
                    length(float3(GetObjectToWorldMatrix()[0].x, GetObjectToWorldMatrix()[1].x, GetObjectToWorldMatrix()[2].x)), // scale x axis
                    length(float3(GetObjectToWorldMatrix()[0].y, GetObjectToWorldMatrix()[1].y, GetObjectToWorldMatrix()[2].y)) // scale y axis
                    );

                float3 posVS = quadPivotPosVS + float3(IN.positionOS.xy * scaleXY_WS,0);//recontruct quad 4 points in view space, now use can use posVS as usual

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //complete SV_POSITION's view space to HClip space transformation
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                OUT.positionHCS = mul(GetViewToHClipMatrix(),float4(posVS,1));

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //do smooth visibility test using brute force forloop
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                float visibilityTestPassedCount = 0;
                float linearEyeDepthOfFlarePivot = -quadPivotPosVS.z;//view space's forward is pointing to -Z, but we want +Z, so negate it
                float testLoopSingleAxisWidth = COUNT*2+1;
                float totalTestCount = testLoopSingleAxisWidth * testLoopSingleAxisWidth;
                float divider = 1.0 / totalTestCount;
                float maxSingleAxisOffset = _LightSourceViewSpaceRadius / testLoopSingleAxisWidth;

                //Test for n*n grid in view space, where quad pivot is grid's center.
                //For each iteration,
                //if that test point passed the scene depth occlusion test, we add 1 to visibilityTestPassedCount
                for(int x = -COUNT; x <= COUNT; x++)
                {
                    for(int y = -COUNT; y <= COUNT ; y++)
                    {
                        float3 testPosVS = quadPivotPosVS;
                        testPosVS.xy += float2(x,y) * maxSingleAxisOffset;//add 2D test grid offset, in const world unit
                        float4 PivotPosCS = mul(GetViewToHClipMatrix(),float4(testPosVS,1));
                        float4 PivotScreenPos = ComputeScreenPos(PivotPosCS);
                        float2 screenUV = PivotScreenPos.xy/PivotScreenPos.w;

                        //if screenUV out of bound, treat it as occluded, because no correct depth texture data can be used to compare
                        if(screenUV.x > 1 || screenUV.x < 0 || screenUV.y > 1 || screenUV.y < 0)
                            continue;

                        //we don't have tex2D() in vertex shader, because rasterization is not done, so use tex2Dlod() with mip0 instead
                        float sampledSceneDepth = tex2Dlod(_CameraDepthTexture,float4(screenUV,0,0)).x;
                        float linearEyeDepthFromSceneDepthTexture = LinearEyeDepth(sampledSceneDepth,_ZBufferParams);
                        float linearEyeDepthFromALU = PivotPosCS.w;

                        //do the actual comparision test
                        //+1 means flare test point is visible in screen space
                        //+0 means flare test point blocked by other objects in screen space, not visible
                        visibilityTestPassedCount += linearEyeDepthFromALU+_DepthOcclusionTestZBias < linearEyeDepthFromSceneDepthTexture ? 1 : 0; 
                    }
                }

                float visibilityResult01 = visibilityTestPassedCount * divider;//0~100% visiblility result 

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //if camera too close to flare , smooth fade out to prevent flare blocking camera too much
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                visibilityResult01 *= smoothstep(_StartFadeinDistanceWorldUnit,_EndFadeinDistanceWorldUnit,linearEyeDepthOfFlarePivot);

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //apply shader flicker animation
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                if(_ShouldDoFlicker)
                {
                    float flickerMul = 0;
                    flickerMul += saturate(sin(_Time.y * _FlickerAnimSpeed * 1.0000)) * (1-_FlickResultIntensityLowestPoint) + _FlickResultIntensityLowestPoint;
                    flickerMul += saturate(sin(_Time.y * _FlickerAnimSpeed * 0.6437)) * (1-_FlickResultIntensityLowestPoint) + _FlickResultIntensityLowestPoint;   
                    visibilityResult01 *= saturate(flickerMul/2);
                }

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //apply all combinations(visibilityResult01) to vertex color (r,g,b only, not a)
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                OUT.color.a *= visibilityResult01;
                OUT.color.rgb *= OUT.color.a;

                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //premultiply alpha to rgb after alpha's calculation is done
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                  
                OUT.color.a = _UsePreMultiplyAlpha? OUT.color.a : 0;
                OUT.color.a = lerp(OUT.color.a, _OverrideAlphaTo, _OverrideAlphaUsage * _ShouldOverrideAlpha);



                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                //pure optimization:
                //if flare is invisible or nearly invisible,
                //move NDC vertex position outside of NDC unit cube,
                //which cause GPU clipping every vertex, this early exit at clipping stage will prevent any rasterization & fragment shader cost at all
                //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
                OUT.positionHCS = visibilityResult01 < divider ? float4(999,999,999,1) : OUT.positionHCS;

                return OUT;
            }

            //Performance cost of rendering a billboard lens flare is 99.9% determined by fragment shader's complexity,
            //In this shader, fragment shader only handles the "look" of flare, without containing any billboard/flare's logic,
            //so this shader is already the FASTEST way to render a billboard lens flare, you can't optimize it further anymore.

            //If you want a different "look", you can always edit the following fragment shader function to fit your project's needs, 
            //all flare logic in vertex shader will still works without problem.
            half4 frag(Varyings IN) : SV_Target
            {
                return saturate(SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv)-_RemoveTextureArtifact) * IN.color;
            }
            ENDHLSL
        }
    }
}
