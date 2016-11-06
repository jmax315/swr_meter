const int DATA= 2;
const int CLOCK= 3;
const int UPDATE= 4;
const int RESET= 5;
const int LOG_AMP_IN= 0;

const int STATE_WAITING_FOR_COMMAND= 1;
const int STATE_TAKING_DATA= 2;
const int STATE_SENDING_DATA= 3;
int state;

unsigned char program_bytes[5]= {
  0x00,
  0x00,
  0x00,
  0x00,
  0x00,
};

unsigned long frequency= 1000000;

unsigned data[1000];
unsigned *data_pointer;
const int num_data_points= sizeof(data)/sizeof(data[0]);

void setup()
{
  pinMode(DATA,OUTPUT);
  pinMode(CLOCK,OUTPUT);
  pinMode(UPDATE,OUTPUT);
  pinMode(RESET,OUTPUT);

  digitalWrite(DATA, 0);
  digitalWrite(CLOCK, 0);
  digitalWrite(UPDATE, 0);
  digitalWrite(RESET, 0);

  digitalWrite(RESET, 1);
  digitalWrite(RESET, 0);

  generate_progamming_bytes();
  send_programming_bytes();
  send_programming_bytes();

  state= STATE_WAITING_FOR_COMMAND;
  Serial.begin(115200);
}

void loop()
{
  switch (state) {
  case STATE_WAITING_FOR_COMMAND:
    {
      long new_freq_in_khz= Serial.parseInt();
      if (!new_freq_in_khz)
        break;
  
      frequency= ((unsigned long) new_freq_in_khz) * 1000;

      generate_progamming_bytes();
      send_programming_bytes();

      data_pointer= &data[0];
      state= STATE_TAKING_DATA;
      break;
    }

  case STATE_TAKING_DATA:
    *data_pointer++ = analogRead(LOG_AMP_IN);

    if (data_pointer - &data[0] > num_data_points) {
      data_pointer= &data[0];
      state= STATE_SENDING_DATA;
    }
    break;

  case STATE_SENDING_DATA:
    Serial.print(frequency);
    Serial.print(",");
    Serial.print(*data_pointer++);
    Serial.print("\r\n");
    if (data_pointer - &data[0] > num_data_points)
      state= STATE_WAITING_FOR_COMMAND;
    break;

  default:
    Serial.print("can't happen\r\n");
    break;
  }
}

void send_programming_bytes()
{
  for (int byte_index= 0; byte_index < sizeof(program_bytes)/sizeof(program_bytes[0]); byte_index++) {
    unsigned char byte= program_bytes[byte_index];
    for (int bit_index= 0; bit_index < 8; bit_index++) {
      digitalWrite(DATA, byte & 0x1);
      digitalWrite(CLOCK, 1);
      digitalWrite(CLOCK, 0);
      byte >>= 1;
    }
  }
  digitalWrite(UPDATE, 1);
  digitalWrite(UPDATE, 0);
}

void generate_progamming_bytes()
{
  double clock= 125000000;
  double value= ((double) frequency * 4 * 1024 * 1024 * 1024) / clock;

  unsigned long frequency_value= (unsigned long) (value);
  unsigned phase_value= ((unsigned long) (value * 32 + 0.5)) & 0x1f;

  program_bytes[0]= frequency_value         & 0xff;
  program_bytes[1]= (frequency_value >>  8) & 0xff;
  program_bytes[2]= (frequency_value >> 16) & 0xff;
  program_bytes[3]= (frequency_value >> 24) & 0xff;
  program_bytes[4]= (phase_value << 3) & 0xf8;
}
