#include "Uniforms.hlsl"
#include "Samplers.hlsl"
#include "Transform.hlsl"
#include "Fog.hlsl"

void VS(float4 iPos : POSITION,
    float2 iTexCoord : TEXCOORD0,
	float3 iNormal : NORMAL,
	
    #ifdef VERTEXCOLOR
        float4 iColor : COLOR0,
    #endif
    #ifdef SKINNED
        float4 iBlendWeights : BLENDWEIGHT,
        int4 iBlendIndices : BLENDINDICES,
    #endif
    #ifdef INSTANCED
        float4x3 iModelInstance : TEXCOORD2,
    #endif
    #ifdef BILLBOARD
        float2 iSize : TEXCOORD1,
    #endif
    out float2 oTexCoord : TEXCOORD0,
    out float oDepth : TEXCOORD1,
    #ifdef HEIGHTFOG
        out float3 oWorldPos : TEXCOORD8,
    #endif
    #ifdef VERTEXCOLOR
        out float4 oColor : COLOR0,
    #endif
    out float4 oPos : POSITION,
	out float3 oEyeVec : TEXCOORD3,
	out float3 oNormal : TEXCOORD2)
{
    float4x3 modelMatrix = iModelMatrix;
    float3 worldPos = GetWorldPos(modelMatrix);
    oPos = GetClipPos(worldPos);
    oTexCoord = GetTexCoord(iTexCoord);
    oDepth = GetDepth(oPos);
	//oNormal = iNormal;
	oNormal=GetWorldNormal(modelMatrix);
	oEyeVec = cCameraPos - worldPos;
}

void PS(float2 iTexCoord : TEXCOORD0,
    float iDepth : TEXCOORD1,
	float3 iNormal : TEXCOORD2,
	float3 iEyeVec : TEXCOORD3,
    out float4 oColor : COLOR0)
{
    
    float4 diffColor = cMatDiffColor;
   
	
	//float inten=max(dot(iNormal, float3(0,1,0)), 0.0);
	//float inten=dot(iNormal, normalize(iEyeVec))*0.5+0.5;
	float inten=1.0-saturate(dot(iNormal, normalize(iEyeVec)));
	//float inten=1.0 - dot(iNormal, normalize(iEyeVec))*0.5+0.5;
	diffColor*=inten;
	//diffColor*=diffColor;

    
    oColor = diffColor;
}