import { media } from '@kit.MediaKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Observed
export default class Recorder {
  private recorder: media.AVRecorder | undefined = undefined;
  private fileName: string = ''
  recorderState: media.AVRecorderState = 'idle'

  get readyToRecord(): boolean {
    return this.recorderState === 'idle' || this.recorderState === 'released'
  }

  get recording(): boolean {
    return this.recorderState === 'started'
  }


  async start(context: Context) {
    try {
      this.recorder = await media.createAVRecorder()
      this.recorder.on('stateChange', (state: media.AVRecorderState, reason: media.StateChangeReason) => {
        this.recorderState = state
      })
      this.recorder.on('error', (err: BusinessError) => {
        console.error(`avRecorder failed, code is ${err.code}, message is ${err.message}`);
      })

      let avProfile: media.AVRecorderProfile = {
        audioBitrate: 100000,
        audioChannels: 2,
        audioCodec: media.CodecMimeType.AUDIO_AAC,
        audioSampleRate: 48000,
        fileFormat: media.ContainerFormatType.CFT_MPEG_4A
      };

      let filePath: string = `${context.filesDir}/example_audio1.mp3`;
      this.fileName = filePath.split('/').pop() as string
      let audioFile: fs.File = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
      let fileFd = audioFile.fd;

      let avConfig: media.AVRecorderConfig = {
        audioSourceType: media.AudioSourceType.AUDIO_SOURCE_TYPE_MIC,
        profile: avProfile,
        url: `fd://${fileFd.toString()}`
      };

      await this.recorder.prepare(avConfig)
      await this.recorder.start();
    } catch (e) {
      console.error('start err:', e.code, e.message)
    }
    finally {
      fs.close(fs.OpenMode.CREATE | fs.OpenMode.READ_WRITE);
    }
  }

  async stopAndSave() {
    try {
      await this.recorder?.stop()
      await this.recorder?.reset()
      await this.recorder?.release();
      this.recorder = undefined;

      return this.fileName
    } catch (e) {
      console.error('stop err:', e.code, e.message)
      throw new Error(e.message)
    }
  }
}