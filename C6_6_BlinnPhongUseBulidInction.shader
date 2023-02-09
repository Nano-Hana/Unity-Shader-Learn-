// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'
Shader "Unity Learn/C6_6/BlinnPhongUseBuildInunction"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("Specular",Color) = (1,1,1,1)
        _Gloss("Gloss",Range(8.0,256)) = 20
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
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                fixed3 worldNormal:TEXCOORD0;//�޸Ĳ���
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                //�Ѷ�������ת�����ü��ռ�
                o.pos=UnityObjectToClipPos(v.vertex);
                //����ռ��µķ��ߴ��ݸ�ƬԪ
                //o.worldNormal=mul(v.normal,(float3x3)unity_WorldToObject);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                //��������ת����������
                o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_TARGET
            {
                //��û���������
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                //���������������ֵ
                fixed3 worldNormal = normalize(i.worldNormal);
                //��ù��߷���
                //fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                //��������ģ����������� Cdiffuse=(Clight*Mdiffuse)max(0,n*l)
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));

                //��÷��䷽��
                //fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));
                //����ӽǷ���
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                //
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                //����߹�
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,(worldNormal,halfDir)),_Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
