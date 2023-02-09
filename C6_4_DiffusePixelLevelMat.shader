// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "Unity Learn/C6_4/Diffuse PixelLevel"
{
    Properties
    {
        _Diffuse("Diffuse",Color)=(1,1,1,1)
    }
    SubShader
    {
        Pass
        {
            Tags {"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal:TEXCOORD0;//修改部分
            };

            v2f vert(a2v v)
            {
                v2f o;
                //把顶点坐标转换到裁剪空间
                o.pos=UnityObjectToClipPos(v.vertex);
                //世界空间下的法线传递给片元
                o.worldNormal=mul(v.normal,(float3x3)unity_WorldToObject);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                //获得环境光数据
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //法线在世界坐标的值
                fixed3 worldNormal = normalize(i.worldNormal);
                //获得光线方向
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                //基本光照模型漫反射计算 Cdiffuse=(Clight*Mdiffuse)max(0,n*l)
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));
                //环境光与漫反射相加
                fixed3 color=ambient+diffuse;

                return fixed4(color, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
