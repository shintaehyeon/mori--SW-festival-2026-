package com.puchipa.carebridge

import android.app.Activity
import android.os.Bundle
import android.widget.ScrollView
import android.widget.TextView

class HealthPrivacyActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val text = TextView(this)
        text.setPadding(32, 48, 32, 48)
        text.textSize = 18f
        text.text = """MORI 건강정보 권한 안내 / Health data permissions

선택한 심박수·수면 및 시각·출처 정보를 최근 24시간 범위에서 이 앱 화면에 표시합니다. 데이터는 화면 실행 메모리에서만 처리하며 화면 종료·읽기 중단 시 지웁니다. 서버·AI·가족·기관에 전송하지 않습니다. OS의 원본 기록은 삭제하지 않습니다.

Reads selected heart-rate and sleep records, timestamps and source information from the past 24 hours for display only. Records remain in view memory, cleared on closing or stopping. No server, AI or third-party transfer. Original Health Connect data is not deleted.

앱의 워치 화면에서 수집·이용 및 민감정보 처리에 별도로 동의한 다음 OS 권한을 선택합니다. 거절해도 수동 기능은 이용 가능합니다. Health Connect > 앱 권한 > MORI에서 언제든 권한을 철회할 수 있습니다.

Prototype policy 2026-10-28-local-v1. 운영 주체·문의 창구를 포함한 최종 처리방침 및 스토어 심사는 배포 전 완료해야 합니다. 진단·실시간 감시·응급 자동 신고 서비스가 아닙니다.
"""
        val scroll = ScrollView(this)
        scroll.addView(text)
        setContentView(scroll)
    }
}
