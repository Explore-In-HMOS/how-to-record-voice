import { abilityAccessCtrl, PermissionRequestResult, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import Recorder from '../services/RecorderService';
import { AudioService, AudioStatus } from '../services/AudioService';
import { hilog } from '@kit.PerformanceAnalysisKit';

@Entry
@Component
struct Index {
  @State isRecording: boolean = false;
  @State recorder: Recorder = new Recorder()
  audioService: AudioService = AudioService.getInstance();
  private filesDir = this.getUIContext().getHostContext()?.filesDir!
  private permissions : Array<Permissions> = ['ohos.permission.MICROPHONE']

  onDidBuild(): void {
    this.requestMicPermission()
  }

  async requestMicPermission() {
    const atManager: abilityAccessCtrl.AtManager = abilityAccessCtrl.createAtManager();
    const context = this.getUIContext().getHostContext()
    atManager.requestPermissionsFromUser(context, this.permissions)
      .then((data: PermissionRequestResult) => {
        hilog.info(0x0000, '',
          `Permissions have been granted`)
      })
      .catch((err: BusinessError) => {
        hilog.error(0x0000, '',
          `Failed to request permissions from user. Code is ${err.code}, message is ${err.message}`);
      })
  }

  async startRecording(): Promise<void> {
    if (this.recorder.readyToRecord) {
      this.isRecording = true;
      await this.recorder.start(this.getUIContext().getHostContext()!)
    }
  }

  async stopRecording(): Promise<void> {
    if (this.recorder.recording) {
      await this.recorder.stopAndSave()
      this.isRecording = false;
      this.audioService.canPlay = true;
    }
  }

  playAudio() {
    this.audioService.playAudioFromFile(this.filesDir + `/example_audio1.mp3`)
  }

  finishAudio() {
    this.audioService.canPlay = false;
    this.audioService.pause()
  }

  build() {
    Stack() {
      if (this.isRecording) {
        Progress({ value: 0, total: 100, type: ProgressType.Ring })
          .width('100%')
          .color(Color.Blue)
          .style({ strokeWidth: 10, status: ProgressStatus.LOADING })
      }
      Column() {
        if (!this.audioService.canPlay) {
          Text(this.isRecording ? 'Stop' : 'Start') {
          }
          .width('30%')
          .backgroundColor(Color.Blue)
          .borderRadius(8)
          .fontWeight(FontWeight.Bold)
          .padding({
            left: 10,
            right: 10,
            top: 5,
            bottom: 5
          })
          .onClick(() => {
            if (this.isRecording) {
              this.stopRecording();
            } else if (!this.isRecording) {
              this.startRecording();
            }
          })
        }
        if (this.audioService.canPlay ) {
          Text('Play') {
          }
          .width('30%')
          .backgroundColor(Color.Blue)
          .borderRadius(8)
          .fontWeight(FontWeight.Bold)
          .padding({
            left: 10,
            right: 10,
            top: 5,
            bottom: 5
          })
          .onClick(() => {
            if (this.audioService.audioStatus === AudioStatus.Playing) {
              this.finishAudio();
            } else {
              this.playAudio();
            }
          })
        }
      }
      .height('100%')
      .width('100%')
      .justifyContent(FlexAlign.Center)
    }
    .height('100%')
    .width('100%')
  }
}