package br.com.moreto.biblia.app

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.speech.RecognizerIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private var ditadoPendente: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Ditado do sistema: abre a janela "Fale agora" do Google e devolve o texto falado (nulo se cancelar).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CANAL_DITADO).setMethodCallHandler { call, result ->
            when (call.method) {
                "disponivel" -> result.success(
                    Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).resolveActivity(packageManager) != null
                )
                "ditar" -> ditar(call.argument<String>("idioma"), call.argument<String>("dica"), result)
                else -> result.notImplemented()
            }
        }
    }

    private fun ditar(idioma: String?, dica: String?, result: MethodChannel.Result) {
        ditadoPendente?.success(null)
        ditadoPendente = result
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
            putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            idioma?.let { putExtra(RecognizerIntent.EXTRA_LANGUAGE, it) }
            dica?.let { putExtra(RecognizerIntent.EXTRA_PROMPT, it) }
        }
        try {
            startActivityForResult(intent, CODIGO_DITADO)
        } catch (e: ActivityNotFoundException) {
            ditadoPendente = null
            result.error("indisponivel", e.message, null)
        }
    }

    @Deprecated("startActivityForResult")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CODIGO_DITADO) return
        val texto = if (resultCode == Activity.RESULT_OK) {
            data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
        } else {
            null
        }
        ditadoPendente?.success(texto)
        ditadoPendente = null
    }

    companion object {
        private const val CANAL_DITADO = "br.com.moreto.biblia.app/ditado"
        private const val CODIGO_DITADO = 4801
    }
}
