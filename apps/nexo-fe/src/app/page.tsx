import type { Metadata } from 'next';

export const metadata: Metadata = {
  title: 'Home - Nexo',
  description: 'Podemos começar a construir algo incrível juntos!',
};

const HomePage = () => {
  return (
    <div>
      <h1 className="text-3xl font-bold text-center mt-8">
        Podemos começar a construir algo incrível juntos!
      </h1>
    </div>
  );
};

export default HomePage;
