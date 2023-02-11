// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "Unity Learn/C7_1/SingleTextrue"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1)     //漫反射颜色
		_MainTex ("Main Tex", 2D) = "white" {}          //纹理
		_Specular ("Specular", Color) = (1, 1, 1, 1)    //高光颜色
		_Gloss ("Gloss", Range(8.0, 256)) = 20          //高光范围
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

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;   //ST是缩放和变换的缩写 命名是按照纹理名称加_ST
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal:TEXCOORD0;//修改部分
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                //把顶点坐标转换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                //世界空间下的法线传递给片元
                //o.worldNormal=mul(v.normal,(float3x3)unity_WorldToObject);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                //顶点坐标转换世界坐标
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                //得到纹理坐标，先缩放再偏移 注释的是原始公式 使用的是Unity内置方法会调用 纹理名_ST 的变量
                //o.uv =  v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                //法线在世界坐标的值
                fixed3 worldNormal = normalize(i.worldNormal);
                //获得光线方向
                //fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //获得环境光数据
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //基本光照模型漫反射计算 Cdiffuse=(Clight*Mdiffuse)max(0,n*l)
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal,worldLightDir));

                //获得反射方向
                //fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                //获得视角方向
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                //
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                //计算高光
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}
