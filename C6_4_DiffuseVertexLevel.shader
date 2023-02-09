// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "Unity Learn/C6_4/Diffuse VertexLevel"
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
                fixed3 color : COLOR;
            };

            v2f vert(a2v v)
            {
                v2f o;
                //把顶点坐标转换到裁剪空间
                o.pos=UnityObjectToClipPos(v.vertex);

                //获得Unity中环境光的数据
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //漫反射计算
                //将顶点法线坐标转换到世界坐标（统一坐标系才能够计算）
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                //获取光源信息
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                //基本光照模型漫反射计算 Cdiffuse=(Clight*Mdiffuse)max(0,n*l)
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));
                //环境光与漫反射相加
                o.color = ambient+diffuse;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                return fixed4(i.color, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
